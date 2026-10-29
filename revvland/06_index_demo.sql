-- REVVLAND : extension 1, indexing experiment. Run after 05_extensions.sql (or any time after 01_tables.sql).
-- It uses a separate test table (Reg_Perf) so your real Registration data and the capacity triggers are untouched.
-- Result is measured, not assumed: an index is not guaranteed to help, so read the numbers it prints.
SET DEFINE OFF
SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100
SET TIMING ON

BEGIN EXECUTE IMMEDIATE 'DROP TABLE Reg_Perf PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE TABLE Reg_Perf (
  Registration_ID NUMBER PRIMARY KEY,
  Rider_ID NUMBER NOT NULL,
  Event_ID NUMBER NOT NULL,
  Category_ID NUMBER NOT NULL,
  Registration_Status VARCHAR2(15) NOT NULL
);

-- 200,000 rows, 50 events, skewed status: about 85% Confirmed, 10% Pending, 5% Cancelled
INSERT INTO Reg_Perf
SELECT id, TRUNC(DBMS_RANDOM.VALUE(1, 5001)), ev, TRUNC(DBMS_RANDOM.VALUE(1, 5)),
       CASE WHEN rnd < 0.05 THEN 'Cancelled' WHEN rnd < 0.15 THEN 'Pending' ELSE 'Confirmed' END
  FROM (SELECT LEVEL AS id, TRUNC(DBMS_RANDOM.VALUE(1, 51)) AS ev, DBMS_RANDOM.VALUE AS rnd
          FROM dual CONNECT BY LEVEL <= 200000);
COMMIT;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'REG_PERF')

PROMPT ===== Rows and status mix =====
SELECT Registration_Status, COUNT(*) AS n, ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (), 1) AS pct
  FROM Reg_Perf GROUP BY Registration_Status ORDER BY n DESC;

-- Timing helper: runs the search for 50 events x 10 rounds and prints elapsed time and logical reads (if v$ views are readable)
CREATE OR REPLACE PROCEDURE perf_run (p_label VARCHAR2, p_status VARCHAR2) IS
  t0 NUMBER; n NUMBER := 0; lr0 NUMBER; lr1 NUMBER;
  FUNCTION logical_reads RETURN NUMBER IS v NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT s.value FROM v$mystat s JOIN v$statname m ON m.statistic# = s.statistic# WHERE m.name = ''session logical reads''' INTO v;
    RETURN v;
  EXCEPTION WHEN OTHERS THEN RETURN NULL;
  END;
BEGIN
  lr0 := logical_reads;
  t0 := DBMS_UTILITY.GET_TIME;
  FOR round_no IN 1 .. 10 LOOP
    FOR ev IN 1 .. 50 LOOP
      FOR r IN (SELECT Registration_ID, Rider_ID, Category_ID FROM Reg_Perf
                 WHERE Event_ID = ev AND Registration_Status = p_status) LOOP
        n := n + 1;
      END LOOP;
    END LOOP;
  END LOOP;
  lr1 := logical_reads;
  DBMS_OUTPUT.PUT_LINE(RPAD(p_label, 28) || ' status=' || RPAD(p_status, 10) || ' rows=' || n ||
    '  time=' || (DBMS_UTILITY.GET_TIME - t0) / 100 || 's' ||
    '  logical reads=' || NVL(TO_CHAR(lr1 - lr0), 'n/a (no access to v$ views)'));
END;
/

PROMPT ===== BEFORE: no index on (Event_ID, Registration_Status) =====
EXPLAIN PLAN FOR SELECT Registration_ID, Rider_ID, Category_ID FROM Reg_Perf WHERE Event_ID = 7 AND Registration_Status = 'Pending';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +COST +ROWS'));
EXEC perf_run('before index, rare status', 'Pending')
EXEC perf_run('before index, common status', 'Confirmed')

PROMPT ===== Create the candidate composite index =====
CREATE INDEX idx_regperf_event_status ON Reg_Perf (Event_ID, Registration_Status);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'REG_PERF', cascade => TRUE)
SELECT index_name, distinct_keys, clustering_factor, leaf_blocks FROM user_indexes WHERE table_name = 'REG_PERF';

PROMPT ===== AFTER: with the index =====
EXPLAIN PLAN FOR SELECT Registration_ID, Rider_ID, Category_ID FROM Reg_Perf WHERE Event_ID = 7 AND Registration_Status = 'Pending';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +COST +ROWS'));
EXEC perf_run('after index, rare status', 'Pending')
EXEC perf_run('after index, common status', 'Confirmed')

PROMPT ===== Selectivity: what share of the table each (Event_ID, Status) value matches =====
SELECT Registration_Status, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM Reg_Perf) / 50, 2) AS pct_of_table_per_event
  FROM Reg_Perf GROUP BY Registration_Status ORDER BY 2;

PROMPT Compare the lines above. Expect a clear gain for the rare status (Pending, Cancelled);
PROMPT for the common status (Confirmed) the optimizer may still choose a full scan, so the gain can be small.
PROMPT Clean up with:  DROP TABLE Reg_Perf PURGE;  DROP PROCEDURE perf_run;
