"""Concurrency test for capacity-controlled registration.

10 riders try to register at the same moment for Night Sprint (event 3) in the 85cc class (category 1),
which has only 2 places. If the locking works, exactly 2 succeed and 8 get ORA-20011.

Run:  python concurrency_test.py          (cleans up the test registrations afterwards)
      python concurrency_test.py --keep   (leaves them in the database so you can look at them)
"""
import os
import sys
import threading
import oracledb

DSN = "localhost:1521/XEPDB1"
USER = "revvland"
PASSWORD = os.getenv("DB_PASS", "Revvland123")
EVENT, CATEGORY, RIDERS = 3, 1, list(range(1, 11))

results = {}
gate = threading.Barrier(len(RIDERS))


def worker(rider):
    conn = oracledb.connect(user=USER, password=PASSWORD, dsn=DSN)
    cur = conn.cursor()
    gate.wait()  # everyone starts together
    try:
        cur.callproc("register_rider", [rider, EVENT, CATEGORY, 1500])
        results[rider] = "REGISTERED"
    except oracledb.DatabaseError as e:
        results[rider] = e.args[0].message.split("\n")[0]
    finally:
        conn.close()


def main():
    keep = "--keep" in sys.argv
    conn = oracledb.connect(user=USER, password=PASSWORD, dsn=DSN)
    cur = conn.cursor()

    # start from a clean slate for this event so the test can be repeated
    cur.execute("DELETE FROM Payment WHERE Registration_ID IN (SELECT Registration_ID FROM Registration WHERE Event_ID = :e)", e=EVENT)
    cur.execute("DELETE FROM Registration WHERE Event_ID = :e", e=EVENT)
    conn.commit()
    cur.execute("SELECT Max_Places, Places_Taken FROM Event_Capacity WHERE Event_ID = :e AND Category_ID = :c", e=EVENT, c=CATEGORY)
    print("Before: max places %s, taken %s" % cur.fetchone())

    threads = [threading.Thread(target=worker, args=(r,)) for r in RIDERS]
    [t.start() for t in threads]
    [t.join() for t in threads]

    for r in RIDERS:
        print("  rider %2d -> %s" % (r, results[r]))
    ok = sum(1 for v in results.values() if v == "REGISTERED")

    cur.execute("SELECT Max_Places, Places_Taken FROM Event_Capacity WHERE Event_ID = :e AND Category_ID = :c", e=EVENT, c=CATEGORY)
    mx, taken = cur.fetchone()
    cur.execute("SELECT COUNT(*) FROM Registration WHERE Event_ID = :e AND Category_ID = :c AND Registration_Status <> 'Cancelled'", e=EVENT, c=CATEGORY)
    real = cur.fetchone()[0]
    print("After: max %s, Places_Taken %s, actual registrations %s, successful calls %s" % (mx, taken, real, ok))
    print("PASS: no overbooking" if ok == real == taken <= mx else "FAIL: counts disagree")

    if not keep:
        cur.execute("DELETE FROM Payment WHERE Registration_ID IN (SELECT Registration_ID FROM Registration WHERE Event_ID = :e)", e=EVENT)
        cur.execute("DELETE FROM Registration WHERE Event_ID = :e", e=EVENT)  # trigger releases the places
        conn.commit()
        print("Test registrations removed.")
    conn.close()


if __name__ == "__main__":
    main()
