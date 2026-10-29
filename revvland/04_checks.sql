-- REVVLAND : checks and demo queries. Run last.
SET LINESIZE 200
SET PAGESIZE 50
COLUMN Name FORMAT A20
COLUMN Event_Name FORMAT A18
COLUMN Race_Name FORMAT A14
-- 1. Row counts (expect Staff 3, Category 4, Rider 10, Event 4, Bike 10, Registration 15, Payment 15, Race 6, Track_Booking 4, Race_Participant 12, Result 12)
SELECT 'Staff' AS tbl, COUNT(*) AS n FROM Staff UNION ALL SELECT 'Category', COUNT(*) FROM Category UNION ALL SELECT 'Rider', COUNT(*) FROM Rider UNION ALL SELECT 'Event', COUNT(*) FROM Event UNION ALL SELECT 'Bike', COUNT(*) FROM Bike UNION ALL SELECT 'Registration', COUNT(*) FROM Registration UNION ALL SELECT 'Payment', COUNT(*) FROM Payment UNION ALL SELECT 'Race', COUNT(*) FROM Race UNION ALL SELECT 'Track_Booking', COUNT(*) FROM Track_Booking UNION ALL SELECT 'Race_Participant', COUNT(*) FROM Race_Participant UNION ALL SELECT 'Result', COUNT(*) FROM Result;
-- 2. Who is registered for each event
SELECT e.Event_Name, r.Name, c.Category_Name, g.Registration_Status FROM Registration g JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Event e ON e.Event_ID = g.Event_ID JOIN Category c ON c.Category_ID = g.Category_ID ORDER BY e.Event_ID, r.Name;
-- 3. Riders per event
SELECT e.Event_Name, COUNT(*) AS Riders FROM Registration g JOIN Event e ON e.Event_ID = g.Event_ID GROUP BY e.Event_ID, e.Event_Name ORDER BY e.Event_ID;
-- 4. Registrations that are not paid
SELECT g.Registration_ID, r.Name, p.Payment_Status FROM Registration g JOIN Rider r ON r.Rider_ID = g.Rider_ID JOIN Payment p ON p.Registration_ID = g.Registration_ID WHERE p.Payment_Status <> 'Paid';
-- 5. Revenue per event (paid only)
SELECT e.Event_Name, SUM(p.Amount) AS Revenue FROM Payment p JOIN Registration g ON g.Registration_ID = p.Registration_ID JOIN Event e ON e.Event_ID = g.Event_ID WHERE p.Payment_Status = 'Paid' GROUP BY e.Event_ID, e.Event_Name ORDER BY e.Event_ID;
-- 6. Race results
SELECT ra.Race_Name, r.Name, x.Position, x.Points, x.Status FROM Result x JOIN Race ra ON ra.Race_ID = x.Race_ID JOIN Rider r ON r.Rider_ID = x.Rider_ID ORDER BY ra.Race_ID, x.Position;
-- 7. Leaderboard (Rohan Iyer should lead with 50 points)
SELECT * FROM v_leaderboard ORDER BY Pos, Name;
-- 8. TEST: payment trigger (registration 13 should flip from Pending to Confirmed)
UPDATE Payment SET Payment_Status = 'Paid', Payment_Date = SYSDATE, Payment_Method = 'UPI', Transaction_Reference = 'TXN100013' WHERE Payment_ID = 13;
SELECT Registration_ID, Registration_Status FROM Registration WHERE Registration_ID = 13;
COMMIT;
-- 9. TEST: bike trigger (should FAIL with ORA-20001: a 450cc bike in the 125cc race)
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (1, 6, 6, 4);
-- 10. TEST: track clash (should FAIL with ORA-20002)
EXEC book_track(1, DATE '2026-11-15', '10:00', '12:00')
-- 11. TEST: constraint (should FAIL with ORA-02290, a check constraint violated)
UPDATE Registration SET Registration_Status = 'Done' WHERE Registration_ID = 1;
-- 12. TEST: duplicate registration (should FAIL with ORA-00001, unique constraint violated)
INSERT INTO Registration (Rider_ID, Event_ID, Category_ID) VALUES (1, 1, 2);
