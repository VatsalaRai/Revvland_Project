-- REVVLAND : extension 2, capacity-controlled registration. Run after 04_checks.sql (or after 03_logic.sql).
-- Safe to re-run: it drops its own objects first.
-- Locking rule used everywhere: lock the Event_Capacity row FIRST (SELECT ... FOR UPDATE), then touch other tables.
SET DEFINE OFF

-- 0. Clean up earlier runs
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_reg_take_place'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_reg_status_place'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_reg_release_place'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_event_capacity'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_category_capacity'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE register_rider'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE cancel_registration'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Event_Capacity CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 1. Capacity table: one row per (event, category)
CREATE TABLE Event_Capacity (
  Event_ID NUMBER NOT NULL REFERENCES Event(Event_ID),
  Category_ID NUMBER NOT NULL REFERENCES Category(Category_ID),
  Max_Places NUMBER NOT NULL CHECK (Max_Places > 0),
  Places_Taken NUMBER DEFAULT 0 NOT NULL,
  CONSTRAINT pk_event_capacity PRIMARY KEY (Event_ID, Category_ID),
  CONSTRAINT ck_places CHECK (Places_Taken >= 0 AND Places_Taken <= Max_Places)
);

-- 2. Seed from existing registrations (cancelled ones do not hold a place). Default limit 20 places.
INSERT INTO Event_Capacity (Event_ID, Category_ID, Max_Places, Places_Taken)
SELECT e.Event_ID, c.Category_ID, 20,
       (SELECT COUNT(*) FROM Registration g
         WHERE g.Event_ID = e.Event_ID AND g.Category_ID = c.Category_ID
           AND g.Registration_Status <> 'Cancelled')
  FROM Event e CROSS JOIN Category c;
-- Small limits so the demo is easy to see
UPDATE Event_Capacity 
SET Max_Places = 3 
WHERE Event_ID = 2 AND Category_ID = 3;  -- already full (3 of 3)

UPDATE Event_Capacity 
SET Max_Places = 2 
WHERE Event_ID = 3 AND Category_ID = 1;  -- used by concurrency_test.py
COMMIT;

-- 3. Every path that creates / cancels / deletes a registration goes through these triggers,
--    so app code, SQL*Plus and the procedures all follow the same locking rule.
CREATE OR REPLACE TRIGGER trg_reg_take_place
BEFORE INSERT ON Registration
FOR EACH ROW
DECLARE
  v_max   NUMBER;
  v_taken NUMBER;
BEGIN
  IF NVL(:NEW.Registration_Status, 'Pending') <> 'Cancelled' THEN
    BEGIN
      SELECT Max_Places, Places_Taken INTO v_max, v_taken
        FROM Event_Capacity
       WHERE Event_ID = :NEW.Event_ID AND Category_ID = :NEW.Category_ID
         FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20010, 'No capacity defined for this event and category');
    END;
    IF v_taken >= v_max THEN
      RAISE_APPLICATION_ERROR(-20011, 'No places left in this category for this event');
    END IF;
    UPDATE Event_Capacity SET Places_Taken = Places_Taken + 1
     WHERE Event_ID = :NEW.Event_ID AND Category_ID = :NEW.Category_ID;
  END IF;
END;
/
CREATE OR REPLACE TRIGGER trg_reg_status_place
AFTER UPDATE OF Registration_Status ON Registration
FOR EACH ROW
DECLARE
  v_max   NUMBER;
  v_taken NUMBER;
BEGIN
  IF :OLD.Registration_Status <> 'Cancelled' AND :NEW.Registration_Status = 'Cancelled' THEN
    -- cancelling releases a place
    SELECT Max_Places INTO v_max FROM Event_Capacity
     WHERE Event_ID = :NEW.Event_ID AND Category_ID = :NEW.Category_ID FOR UPDATE;
    UPDATE Event_Capacity SET Places_Taken = Places_Taken - 1
     WHERE Event_ID = :NEW.Event_ID AND Category_ID = :NEW.Category_ID;
  ELSIF :OLD.Registration_Status = 'Cancelled' AND :NEW.Registration_Status <> 'Cancelled' THEN
    -- un-cancelling needs a free place again
    SELECT Max_Places, Places_Taken INTO v_max, v_taken FROM Event_Capacity
     WHERE Event_ID = :NEW.Event_ID AND Category_ID = :NEW.Category_ID FOR UPDATE;
    IF v_taken >= v_max THEN
      RAISE_APPLICATION_ERROR(-20011, 'No places left in this category for this event');
    END IF;
    UPDATE Event_Capacity SET Places_Taken = Places_Taken + 1
     WHERE Event_ID = :NEW.Event_ID AND Category_ID = :NEW.Category_ID;
  END IF;
END;
/
CREATE OR REPLACE TRIGGER trg_reg_release_place
AFTER DELETE ON Registration
FOR EACH ROW
DECLARE
  v_max NUMBER;
BEGIN
  IF :OLD.Registration_Status <> 'Cancelled' THEN
    SELECT Max_Places INTO v_max FROM Event_Capacity
     WHERE Event_ID = :OLD.Event_ID AND Category_ID = :OLD.Category_ID FOR UPDATE;
    UPDATE Event_Capacity SET Places_Taken = Places_Taken - 1
     WHERE Event_ID = :OLD.Event_ID AND Category_ID = :OLD.Category_ID;
  END IF;
END;
/
-- New events / categories automatically get capacity rows (default 20 places)
CREATE OR REPLACE TRIGGER trg_event_capacity
AFTER INSERT ON Event
FOR EACH ROW
BEGIN
  INSERT INTO Event_Capacity (Event_ID, Category_ID, Max_Places, Places_Taken)
  SELECT :NEW.Event_ID, Category_ID, 20, 0 FROM Category;
END;
/
CREATE OR REPLACE TRIGGER trg_category_capacity
AFTER INSERT ON Category
FOR EACH ROW
BEGIN
  INSERT INTO Event_Capacity (Event_ID, Category_ID, Max_Places, Places_Taken)
  SELECT Event_ID, :NEW.Category_ID, 20, 0 FROM Event;
END;
/

-- 4. Procedures used by the Flask app: lock, check, allocate, all in ONE transaction
CREATE OR REPLACE PROCEDURE register_rider (p_rider NUMBER, p_event NUMBER, p_category NUMBER, p_amount NUMBER) IS
  v_max   NUMBER;
  v_taken NUMBER;
  v_reg   NUMBER;
BEGIN
  -- 1. lock the capacity row (other sessions wait here until we COMMIT or ROLLBACK)
  BEGIN
    SELECT Max_Places, Places_Taken INTO v_max, v_taken
      FROM Event_Capacity
     WHERE Event_ID = p_event AND Category_ID = p_category
       FOR UPDATE;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20010, 'No capacity defined for this event and category');
  END;
  -- 2. check availability
  IF v_taken >= v_max THEN
    RAISE_APPLICATION_ERROR(-20011, 'No places left in this category for this event');
  END IF;
  -- 3. allocate the place (trg_reg_take_place increments Places_Taken) and create the pending payment
  INSERT INTO Registration (Rider_ID, Event_ID, Category_ID) VALUES (p_rider, p_event, p_category)
  RETURNING Registration_ID INTO v_reg;
  INSERT INTO Payment (Registration_ID, Amount) VALUES (v_reg, p_amount);
  COMMIT;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  RAISE;
END;
/
CREATE OR REPLACE PROCEDURE cancel_registration (p_reg NUMBER) IS
  v_event  NUMBER;
  v_cat    NUMBER;
  v_status VARCHAR2(15);
  v_max    NUMBER;
BEGIN
  SELECT Event_ID, Category_ID INTO v_event, v_cat FROM Registration WHERE Registration_ID = p_reg;
  -- same lock order as register_rider: capacity row first, then the registration
  SELECT Max_Places INTO v_max FROM Event_Capacity WHERE Event_ID = v_event AND Category_ID = v_cat FOR UPDATE;
  SELECT Registration_Status INTO v_status FROM Registration WHERE Registration_ID = p_reg FOR UPDATE;
  IF v_status = 'Cancelled' THEN
    RAISE_APPLICATION_ERROR(-20012, 'Registration is already cancelled');
  END IF;
  UPDATE Registration SET Registration_Status = 'Cancelled' WHERE Registration_ID = p_reg;  -- trigger frees the place
  UPDATE Payment
     SET Payment_Status = CASE Payment_Status WHEN 'Paid' THEN 'Refunded' ELSE 'Failed' END
   WHERE Registration_ID = p_reg AND Payment_Status IN ('Pending', 'Paid');
  COMMIT;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  RAISE;
END;
/
SHOW ERRORS

-- 5. Quick checks
COLUMN Event_Name FORMAT A18
COLUMN Category_Name FORMAT A14
SELECT e.Event_Name, c.Category_Name, k.Max_Places, k.Places_Taken, k.Max_Places - k.Places_Taken AS Available
  FROM Event_Capacity k JOIN Event e ON e.Event_ID = k.Event_ID JOIN Category c ON c.Category_ID = k.Category_ID
 ORDER BY e.Event_ID, c.Category_ID;

-- TEST A: should FAIL with ORA-20011 (250cc Dirt Dash Cup is full, 3 of 3)
EXEC register_rider(9, 2, 3, 2500)
-- TEST B: cancel registration 13 (pending, 250cc, event 2), frees a place; then registering rider 9 again would work
EXEC cancel_registration(13)
SELECT Places_Taken 
FROM Event_Capacity 
WHERE Event_ID = 2 AND Category_ID = 3;   -- expect 2
-- TEST C: put it back so the data matches 02_data.sql (registration 13 was cancelled above)
UPDATE Registration SET Registration_Status = 'Pending' WHERE Registration_ID = 13;
UPDATE Payment SET Payment_Status = 'Pending' WHERE Registration_ID = 13;
COMMIT;
SELECT Places_Taken FROM Event_Capacity WHERE Event_ID = 2 AND Category_ID = 3;   -- expect 3 again
