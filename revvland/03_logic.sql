-- REVVLAND : business logic. Run after 02_data.sql. Each block ends with a / on its own line.
SET DEFINE OFF
-- Points scheme (assumed): 1st 25, 2nd 22, 3rd 20, 4th 18, 5th 16, others 0
CREATE OR REPLACE FUNCTION award_points (p_position NUMBER) RETURN NUMBER IS
BEGIN
  RETURN CASE p_position WHEN 1 THEN 25 WHEN 2 THEN 22 WHEN 3 THEN 20 WHEN 4 THEN 18 WHEN 5 THEN 16 ELSE 0 END;
END;
/
-- Points are filled in automatically when a result is entered
CREATE OR REPLACE TRIGGER trg_result_points
BEFORE INSERT OR UPDATE OF Position, Status ON Result
FOR EACH ROW
BEGIN
  IF :NEW.Status = 'Finished' THEN
    :NEW.Points := award_points(:NEW.Position);
  ELSE
    :NEW.Points := 0;
  END IF;
END;
/
-- A bike must fit the engine range of the race category
CREATE OR REPLACE TRIGGER trg_bike_fits_category
BEFORE INSERT OR UPDATE ON Race_Participant
FOR EACH ROW
DECLARE
  v_cc  NUMBER;
  v_min NUMBER;
  v_max NUMBER;
BEGIN
  SELECT Engine_CC INTO v_cc FROM Bike WHERE Bike_ID = :NEW.Bike_ID;
  SELECT c.Min_CC, c.Max_CC INTO v_min, v_max
    FROM Race r JOIN Category c ON c.Category_ID = r.Category_ID
   WHERE r.Race_ID = :NEW.Race_ID;
  IF v_cc < v_min OR v_cc > v_max THEN
    RAISE_APPLICATION_ERROR(-20001, 'Bike engine size does not fit this race category');
  END IF;
END;
/
-- A paid payment confirms the registration
CREATE OR REPLACE TRIGGER trg_payment_confirms
AFTER UPDATE OF Payment_Status ON Payment
FOR EACH ROW
WHEN (NEW.Payment_Status = 'Paid')
BEGIN
  UPDATE Registration SET Registration_Status = 'Confirmed' WHERE Registration_ID = :NEW.Registration_ID;
END;
/
-- Track booking that refuses overlapping times on the same date (times are 'HH24:MI' text)
CREATE OR REPLACE PROCEDURE book_track (p_event NUMBER, p_date DATE, p_start VARCHAR2, p_end VARCHAR2) IS
  v_clash NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_clash FROM Track_Booking
   WHERE Booking_Date = p_date AND Booking_Status = 'Confirmed'
     AND p_start < End_Time AND p_end > Start_Time;
  IF v_clash > 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Track already booked for that time');
  END IF;
  INSERT INTO Track_Booking (Event_ID, Booking_Date, Start_Time, End_Time, Booking_Status)
  VALUES (p_event, p_date, p_start, p_end, 'Confirmed');
  COMMIT;
END;
/
-- Leaderboard
CREATE OR REPLACE VIEW v_leaderboard AS
SELECT r.Name, SUM(x.Points) AS Total_Points, RANK() OVER (ORDER BY SUM(x.Points) DESC) AS Pos
FROM Result x JOIN Rider r ON r.Rider_ID = x.Rider_ID
GROUP BY r.Rider_ID, r.Name;
SHOW ERRORS
