-- REVVLAND : sample data. Run after 01_tables.sql. Order matters (parents first).
SET DEFINE OFF
-- STAFF (3)
INSERT INTO Staff (Staff_ID, Name, Role, Phone, Email) VALUES (1, 'Suresh Kumar', 'Event Director', '9840011111', 'suresh@revvland.in');
INSERT INTO Staff (Staff_ID, Name, Role, Phone, Email) VALUES (2, 'Meera Nair', 'Race Marshal', '9840022222', 'meera@revvland.in');
INSERT INTO Staff (Staff_ID, Name, Role, Phone, Email) VALUES (3, 'Imran Khan', 'Track Manager', '9840033333', 'imran@revvland.in');
-- CATEGORY (4)
INSERT INTO Category (Category_ID, Category_Name, Min_CC, Max_CC, Description) VALUES (1, '85cc Class', 50, 85, 'Entry class for small bikes');
INSERT INTO Category (Category_ID, Category_Name, Min_CC, Max_CC, Description) VALUES (2, '125cc Class', 86, 125, 'Two-stroke 125cc bikes');
INSERT INTO Category (Category_ID, Category_Name, Min_CC, Max_CC, Description) VALUES (3, '250cc Class', 126, 250, 'Intermediate class');
INSERT INTO Category (Category_ID, Category_Name, Min_CC, Max_CC, Description) VALUES (4, '450cc Class', 251, 450, 'Premier class');
-- RIDER (10)
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (1, 'Arjun Mehta', DATE '2001-03-14', '9876501234', 'arjun.mehta@mail.com', '9876500001');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (2, 'Rohan Iyer', DATE '1999-11-02', '9876505678', 'rohan.iyer@mail.com', '9876500002');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (3, 'Karthik Rao', DATE '2003-07-21', '9876509012', 'karthik.rao@mail.com', '9876500003');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (4, 'Aditya Verma', DATE '2000-01-30', '9876503456', 'aditya.verma@mail.com', '9876500004');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (5, 'Siddharth Nair', DATE '2002-05-09', '9876507890', 'siddharth.nair@mail.com', '9876500005');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (6, 'Vikram Singh', DATE '1998-09-17', '9876502345', 'vikram.singh@mail.com', '9876500006');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (7, 'Dev Patel', DATE '2004-12-25', '9876506789', 'dev.patel@mail.com', '9876500007');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (8, 'Kabir Sharma', DATE '2005-08-08', '9876508901', 'kabir.sharma@mail.com', '9876500008');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (9, 'Neha Reddy', DATE '2002-02-19', '9876504567', 'neha.reddy@mail.com', '9876500009');
INSERT INTO Rider (Rider_ID, Name, Date_of_Birth, Phone, Email, Emergency_Contact) VALUES (10, 'Ishaan Gupta', DATE '2006-04-03', '9876509876', 'ishaan.gupta@mail.com', '9876500010');
-- EVENT (4)
INSERT INTO Event (Event_ID, Event_Name, Event_Date, Start_Time, End_Time, Event_Type, Status, Staff_ID) VALUES (1, 'Revvland Open', DATE '2026-11-15', '08:00', '18:00', 'Championship', 'Open', 1);
INSERT INTO Event (Event_ID, Event_Name, Event_Date, Start_Time, End_Time, Event_Type, Status, Staff_ID) VALUES (2, 'Dirt Dash Cup', DATE '2026-12-06', '09:00', '17:00', 'Time Trial', 'Open', 1);
INSERT INTO Event (Event_ID, Event_Name, Event_Date, Start_Time, End_Time, Event_Type, Status, Staff_ID) VALUES (3, 'Night Sprint', DATE '2027-01-10', '17:00', '22:00', 'Exhibition', 'Planned', 2);
INSERT INTO Event (Event_ID, Event_Name, Event_Date, Start_Time, End_Time, Event_Type, Status, Staff_ID) VALUES (4, 'Season Finale', DATE '2027-02-14', '08:00', '18:00', 'Championship', 'Planned', 3);
-- BIKE (10, one per rider; Engine_CC fits the rider's class)
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (1, 1, 'RV-21', 'Yamaha', 'YZ125', 125);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (2, 2, 'RV-44', 'KTM', '250 SX-F', 250);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (3, 3, 'RV-07', 'KTM', '85 SX', 85);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (4, 4, 'RV-12', 'Husqvarna', 'TC125', 125);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (5, 5, 'RV-33', 'Kawasaki', 'KX250', 250);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (6, 6, 'RV-99', 'Honda', 'CRF450R', 450);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (7, 7, 'RV-15', 'Yamaha', 'YZ85', 85);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (8, 8, 'RV-28', 'GasGas', 'MC125', 125);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (9, 9, 'RV-51', 'Suzuki', 'RM-Z250', 250);
INSERT INTO Bike (Bike_ID, Rider_ID, Bike_Number, Brand, Model, Engine_CC) VALUES (10, 10, 'RV-77', 'Husqvarna', 'FC450', 450);
-- REGISTRATION (15)
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (1, 1, 1, 2, DATE '2026-10-01', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (2, 2, 1, 3, DATE '2026-10-01', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (3, 3, 1, 1, DATE '2026-10-02', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (4, 4, 1, 2, DATE '2026-10-02', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (5, 5, 1, 3, DATE '2026-10-03', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (6, 6, 1, 4, DATE '2026-10-03', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (7, 7, 1, 1, DATE '2026-10-04', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (8, 8, 1, 2, DATE '2026-10-04', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (9, 1, 2, 2, DATE '2026-10-10', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (10, 2, 2, 3, DATE '2026-10-10', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (11, 3, 2, 1, DATE '2026-10-11', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (12, 5, 2, 3, DATE '2026-10-11', 'Confirmed');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (13, 9, 2, 3, DATE '2026-10-12', 'Pending');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (14, 10, 2, 4, DATE '2026-10-12', 'Cancelled');
INSERT INTO Registration (Registration_ID, Rider_ID, Event_ID, Category_ID, Registration_Date, Registration_Status) VALUES (15, 4, 2, 2, DATE '2026-10-13', 'Confirmed');
-- PAYMENT (15, one per registration)
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (1, 1, 2000, DATE '2026-10-01', 'UPI', 'Paid', 'TXN100001');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (2, 2, 2500, DATE '2026-10-01', 'Card', 'Paid', 'TXN100002');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (3, 3, 1500, DATE '2026-10-02', 'UPI', 'Paid', 'TXN100003');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (4, 4, 2000, DATE '2026-10-02', 'Cash', 'Paid', 'TXN100004');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (5, 5, 2500, DATE '2026-10-03', 'UPI', 'Paid', 'TXN100005');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (6, 6, 3000, DATE '2026-10-03', 'Net Banking', 'Paid', 'TXN100006');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (7, 7, 1500, DATE '2026-10-04', 'UPI', 'Paid', 'TXN100007');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (8, 8, 2000, DATE '2026-10-04', 'Card', 'Paid', 'TXN100008');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (9, 9, 2000, DATE '2026-10-10', 'UPI', 'Paid', 'TXN100009');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (10, 10, 2500, DATE '2026-10-10', 'Card', 'Paid', 'TXN100010');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (11, 11, 1500, DATE '2026-10-11', 'UPI', 'Paid', 'TXN100011');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (12, 12, 2500, DATE '2026-10-11', 'Cash', 'Paid', 'TXN100012');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (13, 13, 2500, NULL, NULL, 'Pending', NULL);
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (14, 14, 3000, DATE '2026-10-12', 'Net Banking', 'Refunded', 'TXN100014');
INSERT INTO Payment (Payment_ID, Registration_ID, Amount, Payment_Date, Payment_Method, Payment_Status, Transaction_Reference) VALUES (15, 15, 2000, DATE '2026-10-13', 'UPI', 'Paid', 'TXN100015');
-- RACE (6)
INSERT INTO Race (Race_ID, Event_ID, Category_ID, Race_Name, Race_Date, Start_Time, Number_of_Laps) VALUES (1, 1, 2, '125cc Final', DATE '2026-11-15', '10:00', 10);
INSERT INTO Race (Race_ID, Event_ID, Category_ID, Race_Name, Race_Date, Start_Time, Number_of_Laps) VALUES (2, 1, 3, '250cc Final', DATE '2026-11-15', '12:00', 12);
INSERT INTO Race (Race_ID, Event_ID, Category_ID, Race_Name, Race_Date, Start_Time, Number_of_Laps) VALUES (3, 1, 1, '85cc Final', DATE '2026-11-15', '14:00', 8);
INSERT INTO Race (Race_ID, Event_ID, Category_ID, Race_Name, Race_Date, Start_Time, Number_of_Laps) VALUES (4, 2, 2, '125cc Cup', DATE '2026-12-06', '10:30', 8);
INSERT INTO Race (Race_ID, Event_ID, Category_ID, Race_Name, Race_Date, Start_Time, Number_of_Laps) VALUES (5, 2, 3, '250cc Cup', DATE '2026-12-06', '12:30', 10);
INSERT INTO Race (Race_ID, Event_ID, Category_ID, Race_Name, Race_Date, Start_Time, Number_of_Laps) VALUES (6, 1, 4, '450cc Final', DATE '2026-11-15', '15:00', 12);
-- TRACK_BOOKING (4)
INSERT INTO Track_Booking (Booking_ID, Event_ID, Booking_Date, Start_Time, End_Time, Booking_Status) VALUES (1, 1, DATE '2026-11-15', '07:00', '19:00', 'Confirmed');
INSERT INTO Track_Booking (Booking_ID, Event_ID, Booking_Date, Start_Time, End_Time, Booking_Status) VALUES (2, 2, DATE '2026-12-06', '08:00', '18:00', 'Confirmed');
INSERT INTO Track_Booking (Booking_ID, Event_ID, Booking_Date, Start_Time, End_Time, Booking_Status) VALUES (3, 3, DATE '2027-01-10', '16:00', '23:00', 'Pending');
INSERT INTO Track_Booking (Booking_ID, Event_ID, Booking_Date, Start_Time, End_Time, Booking_Status) VALUES (4, 4, DATE '2027-02-14', '07:00', '19:00', 'Pending');
-- RACE_PARTICIPANT (12)
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (1, 1, 1, 1);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (1, 4, 4, 2);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (1, 8, 8, 3);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (2, 2, 2, 1);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (2, 5, 5, 2);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (3, 3, 3, 1);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (3, 7, 7, 2);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (4, 1, 1, 1);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (4, 4, 4, 2);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (5, 2, 2, 1);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (5, 5, 5, 2);
INSERT INTO Race_Participant (Race_ID, Rider_ID, Bike_ID, Gate_Number) VALUES (6, 6, 6, 1);
-- RESULT (12) : lap and total times are in seconds; DNF row has no position or times
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (1, 1, 1, 1, 62.450, 642.300, 25, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (2, 1, 4, 2, 63.120, 650.880, 22, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (3, 1, 8, 3, 64.010, 661.200, 20, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (4, 2, 2, 1, 70.200, 860.400, 25, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (5, 2, 5, 2, 71.010, 872.150, 22, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (6, 3, 3, 1, 58.300, 470.100, 25, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (7, 3, 7, 2, 59.400, 482.700, 22, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (8, 4, 1, 2, 62.900, 515.100, 22, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (9, 4, 4, 1, 62.300, 508.600, 25, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (10, 5, 2, 1, 69.800, 705.300, 25, 'Finished');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (11, 5, 5, NULL, NULL, NULL, 0, 'DNF');
INSERT INTO Result (Result_ID, Race_ID, Rider_ID, Position, Lap_Time, Total_Time, Points, Status) VALUES (12, 6, 6, 1, 75.100, 920.400, 25, 'Finished');
COMMIT;
