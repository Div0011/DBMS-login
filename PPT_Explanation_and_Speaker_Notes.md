# Railway Reservation System (RRS) — PPT Explanation & SQL Guide

This guide gives you simple, ready-to-speak explanations for every slide in `Railway_Reservation_System_Report.pptx` (8 slides) and explains how to run the saved SQLite database (`railway_reservation_system.db`) and all 20 SQL queries (`20_analytical_queries.sql`).

---

## Part 1: Slide-by-Slide Presentation Explanation

### Slide 1 — Front Page (Title Slide)
* **What to say:** *"Good morning/afternoon everyone. Today I am presenting our DBMS project on the **Railway Reservation System (RRS)**. It is designed to handle nationwide train booking scale—over 2.5 million bookings a day—using a clean 12-table database, smart seat-sharing logic, and 20 analytical SQL queries."*

### Slide 2 — Smart Seat Booking (No Wasted Seats)
* **The Problem:** In a basic reservation system, if Passenger 1 books a seat from **Delhi (NDLS) to Kota (KOTA)**, the system locks that seat for the entire train journey all the way to **Mumbai (BCT)**. Anyone wanting to travel from **Kota to Mumbai** is rejected, wasting up to **65%** of seat capacity.
* **Our Solution (Bitmask):** We divide a train route into individual stop-to-stop **legs** (`0` = free, `1` = booked).
  * Passenger 1 (`NDLS → KOTA`) gets mask `[1, 0, 0]`.
  * Passenger 2 (`BRC → BCT`) gets mask `[0, 0, 1]`.
  * Because `[1, 0, 0] & [0, 0, 1] = 0`, there is zero overlap—both passengers share the same physical berth on different parts of the trip, raising seat usage to **>96%**.

### Slide 3 — How It Works (System Architecture)
* **What to say:** *"When 350,000 people open the app at 10:00 AM for Tatkal, traffic flows through 4 layers:"*
  1. **Gatekeeper (Cloudflare WAF & Envoy):** Blocks bots and limits traffic spikes (5 requests/sec per IP).
  2. **Fast Memory (Redis):** Checks free seat bitmasks in under 5 milliseconds and holds your seat for 8 minutes while you pay.
  3. **Safe Database (PostgreSQL):** Uses row locks (`SELECT ... FOR UPDATE`) so two people can never book the same berth.
  4. **Auto-Updates (Kafka):** When someone cancels a ticket, Kafka automatically promotes the next Waitlist/RAC passenger.

### Slide 4 — Complete ER Diagram (All 12 Tables)
* **What to say:** *"Here is our complete Entity-Relationship diagram showing all 12 tables grouped into 4 areas:"*
  * **People & Tickets:** `Users`, `Tickets`, `Passengers`
  * **Trains & Routes:** `Trains`, `Stations`, `Train_Schedules`
  * **Seats & Quotas:** `Coaches`, `Berths`, `Quotas`, `Segment_Inventory`
  * **Payments & Waitlist:** `Payments`, `Waitlist_Queue`
* **Key Relationships:** One user can book many tickets (`1:N`), one ticket can have many passengers (`1:N`), and `Train_Schedules` connects trains to every station stop in order.

### Slide 5 — Clean & Safe Data (Normalization & Tatkal Locking)
* **Database Cleanup (`1NF → BCNF`):**
  * **1NF:** No comma-separated lists—every passenger gets their own row in `Passengers`.
  * **2NF:** Train details stay in `Trains`, not repeated inside every passenger row.
  * **3NF:** Station state/zone stays in `Stations`, not copied into `Tickets`.
  * **BCNF:** `Train_Schedules` enforces unique `(train_no, stop_order)` so stop numbers can never clash.
* **Safe Tatkal Booking (4 Steps):**
  * `0–5ms`: Redis Redlock reserves the berth (`NX PX 480000` = 8-minute hold).
  * `5–25ms`: Database locks the `Segment_Inventory` row.
  * `30–120s`: Payment gateway sends success/failure webhook.
  * `Final`: Ticket becomes `CONFIRMED`, or if payment fails/times out, the seat automatically becomes `AVAILABLE` again.

### Slide 6 — 20 Analytical SQL Queries & Key Insights
* **What to say:** *"We wrote 20 SQL queries across 4 categories to run reports on our database:"*
  * **Q01–Q05 (Basic Search):** Finding Superfast/Vande Bharat trains, senior citizens (60+), waitlist counts, big stations, and high-fare bookings.
  * **Q06–Q10 (Joining Tables):** Printing full PNR passenger charts, train timetables, alert contact lists, UPI payment logs, and direct trains between two cities.
  * **Q11–Q15 (Totals & Revenue):** Revenue per train, passengers per PNR, average fare by class, top 5 origin stations, and payment failure rates.
  * **Q16–Q20 (Advanced Insights):** Spotting heavy booking agents, empty trains for tomorrow, highest-fare ticket, stop-to-stop distances (`LAG()`), and cancelled high-value customers.
* **Chart Insight (Q15):** UPI is the most reliable payment channel (`0.71%` failure rate in the report benchmark) compared to Net Banking (`8.33%`).

### Slide 7 — Conclusion
* **4 Main Takeaways:**
  1. **More Seats Filled:** Leg-by-leg booking achieves **>96%** seat utilization.
  2. **Zero Double-Booking:** Distributed locks keep 350K concurrent Tatkal users safe.
  3. **Clean 12-Table Design:** Fully normalized (`1NF → BCNF`) with zero duplicate data.
  4. **Fast SQL Reports:** Monthly partitioning and indexes keep queries under **150ms**.

### Slide 8 — Thank You
* **What to say:** *"Thank you for your time! I am happy to answer any questions or demonstrate the SQL queries live."*

---

## Part 2: Files Saved in This Folder

| File | Purpose |
| :--- | :--- |
| `railway_reservation_system.db` | Ready-to-use SQLite database preloaded with all 12 tables and sample data. |
| `railway_database.sql` | Full SQL `CREATE TABLE` schema + sample `INSERT` statements. |
| `20_analytical_queries.sql` | All 20 SQL queries (`Q01`–`Q20`) ready to run. |
| `Railway_Reservation_System_Report.pptx` | The 8-slide PowerPoint presentation. |

### How to Run the 20 SQL Queries in Terminal
```bash
cd "/Users/divyansh/Documents/DBMS report"
sqlite3 -header -column railway_reservation_system.db < 20_analytical_queries.sql
```
To rebuild the database from scratch at any time:
```bash
sqlite3 railway_reservation_system.db < railway_database.sql
```
