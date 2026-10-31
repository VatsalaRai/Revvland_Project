# 🏁 Revvland — Motocross Event Management System

**A database-driven web application for managing motocross events, rider registrations, race schedules, payments, and championship standings.**

Revvland is a full-stack academic project developed as part of the **Database Systems** course at Vellore Institute of Technology. It combines a relational database built using **Oracle Database 21c XE** with a **Python Flask** administrative interface.

The project focuses on solving real-world event management challenges through relational database design, data integrity enforcement, query optimization, and concurrency-safe registration.

## Tech Stack

| Layer | Technologies |
|---|---|
| Frontend | HTML, CSS, Jinja2 Templates |
| Backend | Python, Flask |
| Database | Oracle Database 21c XE |
| Database Connectivity | python-oracledb |
| Database Programming | SQL, PL/SQL |
| Database Concepts | ER Modelling, 3NF Normalization, Indexing, Transactions, Row-Level Locking |

## The Problem

Managing a motocross event involves coordinating multiple interconnected operations: rider information, motorcycle specifications, race categories, registrations, payments, track availability, and championship rankings.

Traditional spreadsheet-based management creates problems such as:

- **Data redundancy** from repeatedly storing rider and event information.
- **Inconsistent records** across registrations, payments, and race results.
- **Registration conflicts**, including duplicate entries and overbooked categories.
- **Manual calculations** for championship points and event revenue.
- **Inefficient retrieval** of registration and payment information.

Revvland addresses these challenges through a centralized relational database and a web-based administrative system.

## Key Features

### Rider and Event Management
- Create and manage rider profiles and motorcycle details.
- Organize events, racing categories, and race schedules.
- Assign motorcycles to racing categories based on engine capacity.
- Maintain staff assignments and track bookings.

### Registration and Payment Management
- Register riders for events and racing categories.
- Prevent duplicate registrations.
- Track payment and registration statuses.
- Automatically confirm registrations when payments are marked as paid.
- Support cancellation and capacity release.

### Race Results and Championship Rankings
- Record finishing positions, lap times, and race results.
- Automatically calculate championship points based on finishing position.
- Generate championship leaderboards using SQL aggregation and ranking functions.

### Data Integrity and Business Logic
- Enforce relationships using **primary keys, foreign keys, unique constraints, and check constraints**.
- Implement automated validation using **PL/SQL triggers**.
- Use stored procedures to handle track bookings and registration operations.
- Prevent conflicting track reservations and invalid motorcycle-category assignments.

## System Architecture

Revvland follows a layered client-server architecture:

```text
       Web Browser
       HTML / CSS
           |
           v
    Flask Application
      Python / Jinja2
           |
           v
      python-oracledb
           |
           v
   Oracle Database 21c XE
           |
           v
  Tables, Constraints,
  Triggers, Procedures,
  Functions and Views
```

The Flask application handles routing, administrative sessions, form submissions, and page rendering.

Database operations are executed through `python-oracledb` using bind variables, while business rules are enforced at the database layer to maintain consistency.

## Database Design

The database was designed using an **Entity-Relationship (ER) model** and normalized up to **Third Normal Form (3NF)** to minimize redundancy and prevent insertion, update, and deletion anomalies.

The final schema contains **12 relational tables**, including the capacity-management extension.

**Core entities:** Rider, Bike, Event, Category, Registration, Payment, Race, Race_Participant, Result, Track_Booking, Staff, and Event_Capacity.

Relationships are implemented through foreign keys, with a composite primary key used for race participation.

## Technical Highlights

### 1. Query Optimization Using Composite Indexing

To evaluate registration-search performance, we created a separate test table containing **200,000 generated records**.

A composite index was introduced on:

```sql
CREATE INDEX idx_regperf_event_status
ON Reg_Perf (Event_ID, Registration_Status);
```

The experiment compared query execution plans, elapsed time, and logical reads before and after indexing.

It also examined how query selectivity affects the database optimizer's choice between index scans and full table scans.

### 2. Concurrency-Safe Registration

One of the project's major extensions was preventing race categories from being overbooked when multiple registrations occur simultaneously.

The solution uses **Oracle row-level locking**:

```sql
SELECT Max_Places, Places_Taken
INTO v_max, v_taken
FROM Event_Capacity
WHERE Event_ID = p_event
  AND Category_ID = p_category
FOR UPDATE;
```

This locks the relevant capacity record during registration, ensuring that competing transactions cannot independently allocate the same remaining place.

Registration operations use **COMMIT** and **ROLLBACK** to maintain transactional consistency.

### 3. Automated Business Rules

PL/SQL triggers, stored procedures, functions, and views automate critical operations, including:

- Motorcycle engine-capacity validation.
- Payment-driven registration confirmation.
- Automatic championship-point allocation.
- Track-booking conflict detection.
- Capacity allocation and release.
- Championship leaderboard generation.
- 
## Screenshots 
<img width="2880" height="1390" alt="image" src="https://github.com/user-attachments/assets/c33258aa-d227-4ea0-ae7f-3701f3fa10ba" />
<img width="2880" height="1312" alt="image" src="https://github.com/user-attachments/assets/45d143a9-d170-49d5-94d5-e3a3e07c11b8" />
<img width="2874" height="1290" alt="image" src="https://github.com/user-attachments/assets/2b7009b5-115a-41bc-adc7-181afdc9b00f" />



## Testing and Evaluation

The system was evaluated through SQL verification queries, negative testing, performance experiments, and concurrent registration testing.

**Reported evaluation highlights:**

| Test | Result |
|---|---|
| Database schema | 12 relational tables including extension |
| Sample registrations | 15 |
| Sample payments | 15 |
| Indexing experiment | 200,000 generated records |
| Concurrency experiment | 10 simultaneous sessions competing for 2 places |
| Capacity integrity | No overbooking observed |
| Constraint validation | Invalid inputs correctly rejected |

The tests demonstrated the effectiveness of database-level constraints, transaction handling, and concurrency control for the evaluated scenarios.

## Scope and Future Improvements

The current application focuses on administrative event management and database functionality.

Potential future enhancements include:

- Rider-facing self-service registration.
- Online payment gateway integration.
- Live race timing and results.
- Public championship dashboards.
- Cloud deployment and managed database hosting.

## Project Information

**Developed by:**
- Vatsala Rai
- Vanapalli Yoshita

**Institution:** Vellore Institute of Technology, Vellore  
**Course:** Database Systems  
**Year:** 2026

---

*Revvland demonstrates the practical application of relational database design, PL/SQL business logic, query optimization, and transaction management in a motorsport event management system.*
