# Railway Reservation System (RRS) — DBMS Project

Complete Database Management Systems (`PCC CS-502`) project including ER modeling, 12 normalized tables (`1NF → BCNF / 4NF`), 20 SQL queries with Relational Algebra, a runnable SQLite database, a live Python login backend demo, PowerPoint presentation, and compiled Word report.

## Files in This Repository
- `railway_reservation_system.db` — Ready-to-use SQLite database with 12 normalized tables and sample data.
- `railway_database.sql` — Complete SQL schema (`CREATE TABLE`) and seed data (`INSERT`).
- `20_analytical_queries.sql` — 20 SQL queries (`Q01`–`Q20`) covering selection, projection, joins, aggregations, nested subqueries, and `WITH` clauses.
- `login_app.py` — Simple Python web login page (`http.server` + `sqlite3`) demonstrating backend authentication and Foreign Key joins.
- `Railway_Reservation_System_DBMS_Assignment.docx` — Compiled Word report (Overview, ER Diagram, Connecting Tables, MVD/4NF, 20 Queries + Relational Algebra + Screenshots, Login Demo, Conclusion).
- `Railway_Reservation_System_Report.pptx` — 8-slide PowerPoint presentation.
- `PPT_Explanation_and_Speaker_Notes.md` — Slide-by-slide speaker notes.

## Quick Start

### 1. Run the Login Page Demo
```bash
python3 login_app.py
```
Open `http://127.0.0.1:8080` in your browser and sign in with:
- **Email:** `pooja.h@rail.in` | **User ID:** `u-3312-b56`
- **Email:** `aarav.sharma@rail.in` | **User ID:** `u-1001`

### 2. Run All 20 SQL Queries
```bash
sqlite3 -header -column railway_reservation_system.db < 20_analytical_queries.sql
```
