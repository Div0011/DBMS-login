-- ============================================================================
-- Enterprise Railway Reservation System (RRS) - 20 Analytical & Operational SQL Queries
-- Run against: railway_reservation_system.db (SQLite 3.25+)
-- ============================================================================

-- Q01: Active Superfast & Vande Bharat Services
SELECT train_no, train_name, train_type, source_stn, dest_stn, total_distance_km
FROM Trains
WHERE train_type IN ('SUPERFAST', 'VANDE_BHARAT')
ORDER BY total_distance_km DESC;

-- Q02: Senior Citizen Passenger Audit for Lower Berth Concessions (age >= 60)
SELECT passenger_id, full_name, age, gender, pnr_no, current_status
FROM Passengers
WHERE age >= 60
ORDER BY age DESC;

-- Q03: Real-Time Waitlist Density Extraction for a Journey Date
SELECT t.pnr_no, t.train_no, tr.train_name, t.class_code,
       COUNT(p.passenger_id) AS waitlisted_pax
FROM Tickets t
JOIN Trains tr ON t.train_no = tr.train_no
JOIN Passengers p ON t.pnr_no = p.pnr_no AND t.journey_date = p.journey_date
WHERE t.ticket_status = 'WAITLIST'
  AND t.journey_date = '2026-11-15'
GROUP BY t.pnr_no, t.train_no, tr.train_name, t.class_code;

-- Q04: Station Platform Capacity Audit in Specific State (Maharashtra, >= 5 platforms)
SELECT station_code, station_name, division, railway_zone, platform_count
FROM Stations
WHERE state = 'Maharashtra' AND platform_count >= 5
ORDER BY platform_count DESC;

-- Q05: High-Value Bookings Audit (Anti-Fraud Threshold > 3000 in last 7 days)
SELECT pnr_no, user_id, train_no, total_fare, booking_timestamp
FROM Tickets
WHERE booking_timestamp >= datetime('now', '-7 days')
  AND total_fare > 3000.00
ORDER BY booking_timestamp DESC;

-- Q06: Full PNR Passenger Manifest & Conductor Chart
SELECT t.pnr_no, tr.train_no, tr.train_name, t.journey_date, t.src_station, t.dest_station,
       p.full_name, p.age, p.current_status,
       COALESCE(b.berth_number, 0) AS berth_no,
       COALESCE(c.coach_code, 'N/A') AS coach
FROM Tickets t
JOIN Trains tr ON t.train_no = tr.train_no
JOIN Passengers p ON t.pnr_no = p.pnr_no AND t.journey_date = p.journey_date
LEFT JOIN Berths b ON p.assigned_berth_id = b.berth_id
LEFT JOIN Coaches c ON b.coach_id = c.coach_id
WHERE t.pnr_no = 'PNR1000001';

-- Q07: Sequential Route Timetable with Inter-Station Dwell Times (Train 12951)
SELECT s.stop_order, st.station_name, s.station_code, s.arrival_time,
       s.departure_time, s.halt_minutes, s.distance_from_origin_km
FROM Train_Schedules s
JOIN Stations st ON s.station_code = st.station_code
WHERE s.train_no = 12951
ORDER BY s.stop_order ASC;

-- Q08: Origin Terminal Contact List for Emergency Broadcasts (NDLS today)
SELECT DISTINCT u.user_id, u.full_name, u.email, u.phone_number, t.pnr_no, t.journey_date
FROM Users u
JOIN Tickets t ON u.user_id = t.user_id
WHERE t.src_station = 'NDLS'
  AND t.ticket_status = 'CONFIRMED'
  AND t.journey_date = date('now');

-- Q09: Successful UPI Payment Ledger Reconciliation
SELECT p.transaction_id, p.pnr_no, u.full_name AS booked_by, p.amount_paid, p.payment_timestamp
FROM Payments p
JOIN Tickets t ON p.pnr_no = t.pnr_no AND p.journey_date = t.journey_date
JOIN Users u ON t.user_id = u.user_id
WHERE p.payment_mode = 'UPI' AND p.payment_status = 'SUCCESS'
ORDER BY p.payment_timestamp DESC;

-- Q10: Dual-Halt Route Intersect (Direct Trains Connecting NDLS to BCT)
SELECT s1.train_no, tr.train_name, s1.departure_time, s2.arrival_time,
       (s2.distance_from_origin_km - s1.distance_from_origin_km) AS journey_km
FROM Train_Schedules s1
JOIN Train_Schedules s2 ON s1.train_no = s2.train_no
JOIN Trains tr ON s1.train_no = tr.train_no
WHERE s1.station_code = 'NDLS'
  AND s2.station_code = 'BCT'
  AND s1.stop_order < s2.stop_order;

-- Q11: Gross Revenue Yield per Train Rake (Excluding Cancellations)
SELECT tr.train_no, tr.train_name, COUNT(t.pnr_no) AS confirmed_bookings,
       COALESCE(SUM(t.total_fare), 0.00) AS total_gross_revenue
FROM Trains tr
LEFT JOIN Tickets t ON tr.train_no = t.train_no AND t.ticket_status != 'CANCELLED'
GROUP BY tr.train_no, tr.train_name
ORDER BY total_gross_revenue DESC;

-- Q12: Passenger Headcount Distribution per PNR
SELECT pnr_no, COUNT(passenger_id) AS total_passengers
FROM Passengers
GROUP BY pnr_no
ORDER BY total_passengers DESC;

-- Q13: Average Ticket Fare and Total Yield by Travel Class
SELECT class_code, COUNT(pnr_no) AS total_tickets_sold,
       ROUND(AVG(total_fare), 2) AS average_ticket_fare,
       SUM(total_fare) AS class_total_revenue
FROM Tickets
WHERE ticket_status = 'CONFIRMED'
GROUP BY class_code
ORDER BY class_total_revenue DESC;

-- Q14: Top 5 Origin Junctions by Confirmed Passenger Departures
SELECT st.station_code, st.station_name, st.state,
       COUNT(t.pnr_no) AS total_departures
FROM Stations st
JOIN Tickets t ON st.station_code = t.src_station
WHERE t.ticket_status = 'CONFIRMED'
GROUP BY st.station_code, st.station_name, st.state
ORDER BY total_departures DESC
LIMIT 5;

-- Q15: Payment Gateway Channel Failure Rate Benchmark
SELECT payment_mode, COUNT(*) AS total_attempts,
       SUM(CASE WHEN payment_status = 'FAILED' THEN 1 ELSE 0 END) AS failed_attempts,
       ROUND((SUM(CASE WHEN payment_status = 'FAILED' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS failure_rate_pct
FROM Payments
GROUP BY payment_mode
ORDER BY failure_rate_pct DESC;

-- Q16: Whale Identification (Users Booking Above Platform Average)
SELECT u.user_id, u.full_name, u.email, COUNT(t.pnr_no) AS user_ticket_count
FROM Users u
JOIN Tickets t ON u.user_id = t.user_id
GROUP BY u.user_id, u.full_name, u.email
HAVING COUNT(t.pnr_no) > (
    SELECT AVG(ticket_count)
    FROM (
        SELECT COUNT(pnr_no) AS ticket_count
        FROM Tickets
        GROUP BY user_id
    ) AS user_averages
)
ORDER BY user_ticket_count DESC;

-- Q17: Unutilized Trains with Zero Bookings for Tomorrow (NOT EXISTS Anti-Join)
SELECT tr.train_no, tr.train_name, tr.source_stn, tr.dest_stn
FROM Trains tr
WHERE NOT EXISTS (
    SELECT 1
    FROM Tickets t
    WHERE t.train_no = tr.train_no
      AND t.journey_date = date('now', '+1 day')
      AND t.ticket_status != 'CANCELLED'
);

-- Q18: Single Highest Value Ticket Detection
SELECT p.full_name AS passenger_name, t.pnr_no, t.train_no,
       t.class_code, t.total_fare
FROM Passengers p
JOIN Tickets t ON p.pnr_no = t.pnr_no AND p.journey_date = t.journey_date
WHERE t.total_fare = (
    SELECT MAX(total_fare)
    FROM Tickets
);

-- Q19: Train Route Summary Using WITH Clause (CTE)
WITH Route_Summary AS (
    SELECT train_no, COUNT(station_code) AS total_stops,
           MAX(distance_from_origin_km) AS route_length_km,
           SUM(halt_minutes) AS total_halt_mins
    FROM Train_Schedules
    GROUP BY train_no
)
SELECT tr.train_no, tr.train_name, rs.total_stops, rs.route_length_km, rs.total_halt_mins
FROM Trains tr
JOIN Route_Summary rs ON tr.train_no = rs.train_no
ORDER BY rs.route_length_km DESC;

-- Q20: High-Value Customers Impacted by Ticket Cancellations
SELECT u.user_id, u.full_name, u.email, SUM(t.total_fare) AS gross_spend
FROM Users u
JOIN Tickets t ON u.user_id = t.user_id
WHERE u.user_id IN (
    SELECT DISTINCT user_id
    FROM Tickets
    WHERE ticket_status = 'CANCELLED'
)
GROUP BY u.user_id, u.full_name, u.email
HAVING gross_spend > 1000.00
ORDER BY gross_spend DESC;
