import os
import time
import oracledb
from flask import Flask, render_template, request, redirect, flash, session

app = Flask(__name__)
app.secret_key = os.environ["SECRET_KEY"]

# ---------- database helpers ----------
def db():
    return oracledb.connect(user="revvland", password=os.environ["DB_PASS"],
    dsn="localhost:1521/XEPDB1")

def q(sql, params=None):
    """Run a SELECT. Returns (column names, rows) with dates turned into text."""
    with db() as c:
        cur = c.cursor()
        cur.execute(sql, params or {})
        cols = [d[0] for d in cur.description]
        rows = [tuple(v.strftime("%Y-%m-%d") if hasattr(v, "strftime") else ("" if v is None else v) for v in r)
                for r in cur.fetchall()]
    return cols, rows

def run(stmts):
    """Run one or more INSERT/UPDATE/CALL statements as one transaction. Returns an error text or None."""
    try:
        with db() as c:
            cur = c.cursor()
            for sql, p in stmts:
                cur.execute(sql, p)
            c.commit()
    except oracledb.DatabaseError as e:
        return e.args[0].message.split("\n")[0]
    return None

def opts(sql):
    return [(str(r[0]), r[1]) for r in q(sql)[1]]

def done(err, ok_msg):
    flash(err or ok_msg, "error" if err else "ok")

def F(name, label, kind="text", options=None):
    return (name, label, kind, options)

def num(v, cast=float):
    return cast(v) if v else None

@app.context_processor
def nav():
    return {"nav": [("/", "Dashboard"), ("/riders", "Riders"), ("/events", "Events"),
                    ("/registrations", "Registrations"), ("/payments", "Payments"), ("/races", "Races"),
                    ("/results", "Results"), ("/leaderboard", "Leaderboard"), ("/bookings", "Track Booking"),
                    ("/capacity", "Capacity"), ("/search", "Search"), ("/cancellations", "Cancel")]}

# ---------- admin login ----------
@app.before_request
def guard():
    if request.endpoint not in ("login", "static") and not session.get("admin"):
        return redirect("/login")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form["user"] == os.getenv("ADMIN_USER", "admin") and request.form["pw"] == os.getenv("ADMIN_PW", "admin123"):
            session["admin"] = True
            return redirect("/")
        flash("Wrong username or password", "error")
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/login")

# ---------- pages ----------
@app.route("/")
def dashboard():
    stats = q("""SELECT (SELECT COUNT(*) FROM Rider), (SELECT COUNT(*) FROM Event),
                        (SELECT COUNT(*) FROM Registration),
                        (SELECT COUNT(*) FROM Payment WHERE Payment_Status = 'Pending') FROM dual""")[1][0]
    cols, rows = q("SELECT Event_Name, Event_Date, Event_Type, Status FROM Event ORDER BY Event_Date")
    return render_template("table.html", title="Dashboard", cols=cols, rows=rows,
                           stats=list(zip(["Riders", "Events", "Registrations", "Pending payments"], stats)), sub="Events")

@app.route("/riders", methods=["GET", "POST"])
def riders():
    if request.method == "POST":
        f = request.form
        done(run([("INSERT INTO Rider (Name, Date_of_Birth, Phone, Email, Emergency_Contact) "
                   "VALUES (:n, TO_DATE(:d,'YYYY-MM-DD'), :p, :e, :c)",
                   dict(n=f["name"], d=f["dob"], p=f["phone"], e=f["email"] or None, c=f["emergency"]))]), "Rider added")
        return redirect("/riders")
    cols, rows = q("SELECT Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact FROM Rider ORDER BY Rider_ID")
    form = [F("name", "Name"), F("dob", "Date of birth", "date"), F("phone", "Phone"),
            F("email", "Email (optional)"), F("emergency", "Emergency contact")]
    return render_template("table.html", title="Riders", cols=cols, rows=rows, form=form)

@app.route("/events", methods=["GET", "POST"])
def events():
    if request.method == "POST":
        f = request.form
        done(run([("INSERT INTO Event (Event_Name, Event_Date, Start_Time, End_Time, Event_Type, Status, Staff_ID) "
                   "VALUES (:n, TO_DATE(:d,'YYYY-MM-DD'), :s, :e, :t, :st, :sf)",
                   dict(n=f["name"], d=f["date"], s=f["start"], e=f["end"], t=f["type"], st=f["status"], sf=f["staff"]))]), "Event added")
        return redirect("/events")
    cols, rows = q("SELECT e.Event_ID, e.Event_Name, e.Event_Date, e.Start_Time, e.End_Time, e.Event_Type, e.Status, s.Name AS Staff "
                   "FROM Event e LEFT JOIN Staff s ON s.Staff_ID = e.Staff_ID ORDER BY e.Event_ID")
    form = [F("name", "Event name"), F("date", "Date", "date"), F("start", "Start", "time"), F("end", "End", "time"),
            F("type", "Type", "select", [(t, t) for t in ("Championship", "Time Trial", "Exhibition")]),
            F("status", "Status", "select", [(t, t) for t in ("Planned", "Open", "Completed", "Cancelled")]),
            F("staff", "Staff in charge", "select", opts("SELECT Staff_ID, Name FROM Staff ORDER BY 1"))]
    return render_template("table.html", title="Events", cols=cols, rows=rows, form=form)

@app.route("/registrations", methods=["GET", "POST"])
def registrations():
    if request.method == "POST":
        f = request.form
        done(run([("BEGIN register_rider(:r, :e, :c, :a); END;",
                   dict(r=f["rider"], e=f["event"], c=f["category"], a=f["amount"]))]),
             "Registered. A place was allocated and a pending payment was created.")
        return redirect("/registrations")
    cols, rows = q("SELECT g.Registration_ID, r.Name AS Rider, e.Event_Name, c.Category_Name, g.Registration_Date, g.Registration_Status "
                   "FROM Registration g JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Event e ON e.Event_ID = g.Event_ID "
                   "JOIN Category c ON c.Category_ID = g.Category_ID ORDER BY g.Registration_ID")
    form = [F("rider", "Rider", "select", opts("SELECT Rider_ID, Name FROM Rider ORDER BY Name")),
            F("event", "Event", "select", opts("SELECT Event_ID, Event_Name FROM Event WHERE Status IN ('Open','Planned') ORDER BY Event_Date")),
            F("category", "Category", "select", opts("SELECT Category_ID, Category_Name FROM Category ORDER BY 1")),
            F("amount", "Entry fee", "number")]
    return render_template("table.html", title="Registrations", cols=cols, rows=rows, form=form)

@app.route("/payments", methods=["GET", "POST"])
def payments():
    if request.method == "POST":
        f = request.form
        done(run([("UPDATE Payment SET Payment_Status = 'Paid', Payment_Date = SYSDATE, Payment_Method = :m, "
                   "Transaction_Reference = :t WHERE Payment_ID = :i", dict(m=f["method"], t=f["ref"], i=f["payment"]))]),
             "Payment recorded. The registration is now confirmed.")
        return redirect("/payments")
    cols, rows = q("SELECT p.Payment_ID, r.Name AS Rider, e.Event_Name, p.Amount, p.Payment_Method, p.Payment_Status, p.Payment_Date "
                   "FROM Payment p JOIN Registration g ON g.Registration_ID = p.Registration_ID "
                   "JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Event e ON e.Event_ID = g.Event_ID ORDER BY p.Payment_ID")
    form = [F("payment", "Pending payment", "select",
              opts("SELECT p.Payment_ID, r.Name || ' - ' || e.Event_Name || ' (' || p.Amount || ')' FROM Payment p "
                   "JOIN Registration g ON g.Registration_ID = p.Registration_ID JOIN Rider r ON r.Rider_ID = g.Rider_ID "
                   "JOIN Event e ON e.Event_ID = g.Event_ID WHERE p.Payment_Status = 'Pending' ORDER BY p.Payment_ID")),
            F("method", "Method", "select", [(m, m) for m in ("UPI", "Card", "Cash", "Net Banking")]),
            F("ref", "Transaction reference")]
    return render_template("table.html", title="Payments", cols=cols, rows=rows, form=form)

@app.route("/races", methods=["GET", "POST"])
def races():
    if request.method == "POST":
        f = request.form
        done(run([("INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (:r, :d, :b, "
                   "(SELECT NVL(MAX(Gate_Number), 0) + 1 FROM Race_Participant WHERE Race_ID = :r))",
                   dict(r=f["race"], d=f["rider"], b=f["bike"]))]), "Rider added to the race")
        return redirect("/races")
    cols, rows = q("SELECT ra.Race_Name, e.Event_Name, r.Name AS Rider, b.Bike_Number, b.Engine_CC, p.Gate_Number "
                   "FROM Race_Participant p JOIN Race ra ON ra.Race_ID = p.Race_ID JOIN Event e ON e.Event_ID = ra.Event_ID "
                   "JOIN Rider r ON r.Rider_ID = p.Rider_ID JOIN Bike b ON b.Bike_ID = p.Bike_ID ORDER BY ra.Race_ID, p.Gate_Number")
    form = [F("race", "Race", "select", opts("SELECT Race_ID, Race_Name || ' (' || TO_CHAR(Race_Date,'YYYY-MM-DD') || ')' FROM Race ORDER BY 1")),
            F("rider", "Rider", "select", opts("SELECT Rider_ID, Name FROM Rider ORDER BY Name")),
            F("bike", "Bike", "select", opts("SELECT Bike_ID, Bike_Number || ' - ' || Brand || ' ' || Model || ' (' || Engine_CC || 'cc)' FROM Bike ORDER BY 1"))]
    return render_template("table.html", title="Races", cols=cols, rows=rows, form=form)

@app.route("/results", methods=["GET", "POST"])
def results():
    if request.method == "POST":
        f = request.form
        race, rider = f["entry"].split("-")
        done(run([("INSERT INTO Result (Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Status) VALUES (:r, :d, :p, :l, :t, :s)",
                   dict(r=race, d=rider, p=num(f["position"], int), l=num(f["lap"]), t=num(f["total"]), s=f["status"]))]),
             "Result saved. Points were awarded automatically.")
        return redirect("/results")
    cols, rows = q("SELECT x.Result_ID, ra.Race_Name, r.Name AS Rider, x.Position, x.Lap_Time, x.Total_Time, x.Points, x.Status "
                   "FROM Result x JOIN Race ra ON ra.Race_ID = x.Race_ID JOIN Rider r ON r.Rider_ID = x.Rider_ID ORDER BY x.Race_ID, x.Position")
    form = [F("entry", "Race and rider", "select",
              opts("SELECT p.Race_ID || '-' || p.Rider_ID, ra.Race_Name || ' - ' || r.Name FROM Race_Participant p "
                   "JOIN Race ra ON ra.Race_ID = p.Race_ID JOIN Rider r ON r.Rider_ID = p.Rider_ID WHERE NOT EXISTS "
                   "(SELECT 1 FROM Result x WHERE x.Race_ID = p.Race_ID AND x.Rider_ID = p.Rider_ID) ORDER BY p.Race_ID, p.Rider_ID")),
            F("position", "Position (optional)", "number"), F("lap", "Best lap, seconds (optional)", "number"),
            F("total", "Total time, seconds (optional)", "number"),
            F("status", "Status", "select", [(s, s) for s in ("Finished", "DNF", "DNS", "Disqualified")])]
    return render_template("table.html", title="Results", cols=cols, rows=rows, form=form)

@app.route("/leaderboard")
def leaderboard():
    cols, rows = q("SELECT Pos, Name, Total_Points FROM v_leaderboard ORDER BY Pos, Name")
    return render_template("table.html", title="Leaderboard", cols=cols, rows=rows)

@app.route("/bookings", methods=["GET", "POST"])
def bookings():
    if request.method == "POST":
        f = request.form
        done(run([("BEGIN book_track(:e, TO_DATE(:d,'YYYY-MM-DD'), :s, :t); END;",
                   dict(e=f["event"], d=f["date"], s=f["start"], t=f["end"]))]), "Track booked")
        return redirect("/bookings")
    cols, rows = q("SELECT b.Booking_ID, e.Event_Name, b.Booking_Date, b.Start_Time, b.End_Time, b.Booking_Status "
                   "FROM Track_Booking b JOIN Event e ON e.Event_ID = b.Event_ID ORDER BY b.Booking_Date, b.Start_Time")
    form = [F("event", "Event", "select", opts("SELECT Event_ID, Event_Name FROM Event ORDER BY Event_Date")),
            F("date", "Date", "date"), F("start", "Start", "time"), F("end", "End", "time")]
    return render_template("table.html", title="Track Booking", cols=cols, rows=rows, form=form)


# ---------- extension: capacity ----------
@app.route("/capacity")
def capacity():
    cols, rows = q("SELECT e.Event_Name, c.Category_Name, k.Max_Places, k.Places_Taken, k.Max_Places - k.Places_Taken AS Available "
                   "FROM Event_Capacity k JOIN Event e ON e.Event_ID = k.Event_ID JOIN Category c ON c.Category_ID = k.Category_ID "
                   "ORDER BY e.Event_ID, c.Category_ID")
    return render_template("table.html", title="Capacity", cols=cols, rows=rows)

@app.route("/cancellations", methods=["GET", "POST"])
def cancellations():
    if request.method == "POST":
        done(run([("BEGIN cancel_registration(:i); END;", dict(i=request.form["registration"]))]),
             "Registration cancelled. The place was released.")
        return redirect("/cancellations")
    cols, rows = q("SELECT g.Registration_ID, r.Name AS Rider, e.Event_Name, c.Category_Name, g.Registration_Status "
                   "FROM Registration g JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Event e ON e.Event_ID = g.Event_ID "
                   "JOIN Category c ON c.Category_ID = g.Category_ID ORDER BY g.Registration_ID")
    form = [F("registration", "Registration to cancel", "select",
              opts("SELECT g.Registration_ID, g.Registration_ID || ' - ' || r.Name || ' - ' || e.Event_Name FROM Registration g "
                   "JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Event e ON e.Event_ID = g.Event_ID "
                   "WHERE g.Registration_Status <> 'Cancelled' ORDER BY g.Registration_ID"))]
    return render_template("table.html", title="Cancel Registration", cols=cols, rows=rows, form=form)

# ---------- extension: registration search (the query the composite index is meant for) ----------
@app.route("/search", methods=["GET", "POST"])
def search():
    form = [F("event", "Event", "select", opts("SELECT Event_ID, Event_Name FROM Event ORDER BY Event_Date")),
            F("status", "Registration status", "select", [(s, s) for s in ("Pending", "Confirmed", "Cancelled")])]
    cols, rows = [], []
    if request.method == "POST":
        f = request.form
        t0 = time.perf_counter()
        cols, rows = q("SELECT g.Registration_ID, r.Name AS Rider, c.Category_Name, g.Registration_Date, g.Registration_Status "
                       "FROM Registration g JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Category c ON c.Category_ID = g.Category_ID "
                       "WHERE g.Event_ID = :e AND g.Registration_Status = :s ORDER BY g.Registration_ID",
                       dict(e=f["event"], s=f["status"]))
        flash("%d registration(s) found in %.1f ms" % (len(rows), (time.perf_counter() - t0) * 1000), "ok")
    return render_template("table.html", title="Search Registrations", cols=cols, rows=rows, form=form)

if __name__ == "__main__":
    app.run(debug=True)
