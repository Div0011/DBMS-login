-- ============================================================================
-- Enterprise Railway Reservation System (RRS) - SQLite Database Schema & Seed
-- 12 Core Normalized Entities (1NF -> BCNF)
-- ============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS Waitlist_Queue;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Passengers;
DROP TABLE IF EXISTS Tickets;
DROP TABLE IF EXISTS Segment_Inventory;
DROP TABLE IF EXISTS Quotas;
DROP TABLE IF EXISTS Berths;
DROP TABLE IF EXISTS Coaches;
DROP TABLE IF EXISTS Train_Schedules;
DROP TABLE IF EXISTS Trains;
DROP TABLE IF EXISTS Stations;
DROP TABLE IF EXISTS Users;

-- 1. Users
CREATE TABLE Users (
    user_id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone_number TEXT NOT NULL UNIQUE,
    aadhaar_hash TEXT NOT NULL UNIQUE
);

-- 2. Stations
CREATE TABLE Stations (
    station_code TEXT PRIMARY KEY,
    station_name TEXT NOT NULL,
    division TEXT NOT NULL,
    railway_zone TEXT NOT NULL,
    state TEXT NOT NULL,
    platform_count INTEGER NOT NULL CHECK (platform_count > 0)
);

-- 3. Trains
CREATE TABLE Trains (
    train_no INTEGER PRIMARY KEY,
    train_name TEXT NOT NULL,
    train_type TEXT NOT NULL, -- SUPERFAST, VANDE_BHARAT, EXPRESS
    source_stn TEXT NOT NULL REFERENCES Stations(station_code),
    dest_stn TEXT NOT NULL REFERENCES Stations(station_code),
    total_distance_km INTEGER NOT NULL CHECK (total_distance_km > 0)
);
CREATE INDEX idx_train_type ON Trains(train_type);

-- 4. Train_Schedules (BCNF candidate keys enforced)
CREATE TABLE Train_Schedules (
    schedule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    train_no INTEGER NOT NULL REFERENCES Trains(train_no),
    station_code TEXT NOT NULL REFERENCES Stations(station_code),
    stop_order INTEGER NOT NULL,
    arrival_time TEXT,
    departure_time TEXT,
    halt_minutes INTEGER NOT NULL DEFAULT 0,
    distance_from_origin_km INTEGER NOT NULL DEFAULT 0,
    UNIQUE (train_no, stop_order),
    UNIQUE (train_no, station_code)
);

-- 5. Coaches
CREATE TABLE Coaches (
    coach_id INTEGER PRIMARY KEY AUTOINCREMENT,
    train_no INTEGER NOT NULL REFERENCES Trains(train_no),
    coach_code TEXT NOT NULL, -- B1, A1, H1, C1
    class_code TEXT NOT NULL, -- 3A, 2A, 1A, SL, CC
    capacity INTEGER NOT NULL,
    UNIQUE (train_no, coach_code)
);

-- 6. Berths
CREATE TABLE Berths (
    berth_id INTEGER PRIMARY KEY AUTOINCREMENT,
    coach_id INTEGER NOT NULL REFERENCES Coaches(coach_id),
    berth_number INTEGER NOT NULL,
    berth_type TEXT NOT NULL, -- LOWER, MIDDLE, UPPER, SIDE_LOWER, SIDE_UPPER
    UNIQUE (coach_id, berth_number)
);

-- 7. Quotas
CREATE TABLE Quotas (
    quota_code TEXT PRIMARY KEY,
    quota_name TEXT NOT NULL,
    description TEXT
);

-- 8. Segment_Inventory
CREATE TABLE Segment_Inventory (
    inventory_id INTEGER PRIMARY KEY AUTOINCREMENT,
    train_no INTEGER NOT NULL REFERENCES Trains(train_no),
    berth_id INTEGER NOT NULL REFERENCES Berths(berth_id),
    quota_code TEXT NOT NULL REFERENCES Quotas(quota_code),
    journey_date TEXT NOT NULL,
    from_stop_order INTEGER NOT NULL,
    to_stop_order INTEGER NOT NULL,
    leg_bitmask TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE, LOCKED, BOOKED
    current_pnr TEXT
);
CREATE INDEX idx_inventory_lookup
    ON Segment_Inventory (train_no, journey_date, from_stop_order, to_stop_order, status);

-- 9. Tickets
CREATE TABLE Tickets (
    pnr_no TEXT NOT NULL,
    journey_date TEXT NOT NULL,
    user_id TEXT NOT NULL REFERENCES Users(user_id),
    train_no INTEGER NOT NULL REFERENCES Trains(train_no),
    src_station TEXT NOT NULL REFERENCES Stations(station_code),
    dest_station TEXT NOT NULL REFERENCES Stations(station_code),
    from_stop_order INTEGER NOT NULL,
    to_stop_order INTEGER NOT NULL,
    class_code TEXT NOT NULL,
    base_fare REAL NOT NULL,
    gst_amount REAL NOT NULL,
    total_fare REAL NOT NULL,
    ticket_status TEXT NOT NULL, -- CONFIRMED, WAITLIST, RAC, CANCELLED
    booking_timestamp TEXT NOT NULL,
    PRIMARY KEY (pnr_no, journey_date)
);
CREATE INDEX idx_booking_ts ON Tickets(booking_timestamp);
CREATE INDEX idx_class_code ON Tickets(class_code);

-- 10. Passengers
CREATE TABLE Passengers (
    passenger_id INTEGER PRIMARY KEY AUTOINCREMENT,
    pnr_no TEXT NOT NULL,
    journey_date TEXT NOT NULL,
    full_name TEXT NOT NULL,
    age INTEGER NOT NULL,
    gender TEXT NOT NULL,
    assigned_berth_id INTEGER REFERENCES Berths(berth_id),
    current_status TEXT NOT NULL,
    FOREIGN KEY (pnr_no, journey_date) REFERENCES Tickets(pnr_no, journey_date)
);
CREATE INDEX idx_passengers_age ON Passengers(age);

-- 11. Payments
CREATE TABLE Payments (
    transaction_id TEXT PRIMARY KEY,
    pnr_no TEXT NOT NULL,
    journey_date TEXT NOT NULL,
    payment_mode TEXT NOT NULL, -- UPI, CREDIT_CARD, NET_BANKING
    amount_paid REAL NOT NULL,
    payment_status TEXT NOT NULL, -- SUCCESS, FAILED, REFUNDED
    payment_timestamp TEXT NOT NULL,
    FOREIGN KEY (pnr_no, journey_date) REFERENCES Tickets(pnr_no, journey_date)
);

-- 12. Waitlist_Queue
CREATE TABLE Waitlist_Queue (
    queue_id INTEGER PRIMARY KEY AUTOINCREMENT,
    train_no INTEGER NOT NULL REFERENCES Trains(train_no),
    passenger_id INTEGER NOT NULL REFERENCES Passengers(passenger_id),
    journey_date TEXT NOT NULL,
    class_code TEXT NOT NULL,
    queue_position INTEGER NOT NULL,
    created_at TEXT NOT NULL
);

-- ============================================================================
-- Seed Data
-- ============================================================================

INSERT INTO Users (user_id, full_name, email, phone_number, aadhaar_hash) VALUES
('u-1001', 'Aarav Sharma', 'aarav.sharma@rail.in', '+91-9810000001', 'hash_aadhaar_001'),
('u-3312-b56', 'Pooja Hegde', 'pooja.h@rail.in', '+91-9810000002', 'hash_aadhaar_002'),
('u-4001', 'Suresh Menon', 'suresh.menon@rail.in', '+91-9810000003', 'hash_aadhaar_003'),
('u-7761-c89', 'MakeMyTrip Agent #4', 'agent4@mmt.com', '+91-9810000004', 'hash_aadhaar_004');

INSERT INTO Stations (station_code, station_name, division, railway_zone, state, platform_count) VALUES
('NDLS', 'New Delhi Railway Station', 'Delhi', 'NR', 'Delhi', 16),
('KOTA', 'Kota Junction', 'Kota', 'WCR', 'Rajasthan', 6),
('BRC', 'Vadodara Junction', 'Vadodara', 'WR', 'Gujarat', 7),
('BCT', 'Mumbai Central', 'Mumbai', 'WR', 'Maharashtra', 9),
('CSMT', 'Chhatrapati Shivaji Maharaj Terminus', 'Mumbai', 'CR', 'Maharashtra', 18),
('BSB', 'Varanasi Junction', 'Lucknow', 'NR', 'Uttar Pradesh', 9),
('FZR', 'Firozpur Cantt', 'Firozpur', 'NR', 'Punjab', 4);

INSERT INTO Trains (train_no, train_name, train_type, source_stn, dest_stn, total_distance_km) VALUES
(12951, 'Mumbai Rajdhani Express', 'SUPERFAST', 'NDLS', 'BCT', 1384),
(22436, 'Vande Bharat Express', 'VANDE_BHARAT', 'NDLS', 'BSB', 759),
(12137, 'Punjab Mail', 'SUPERFAST', 'CSMT', 'FZR', 1926);

INSERT INTO Train_Schedules (train_no, station_code, stop_order, arrival_time, departure_time, halt_minutes, distance_from_origin_km) VALUES
(12951, 'NDLS', 1, NULL, '16:55', 0, 0),
(12951, 'KOTA', 2, '21:30', '21:35', 5, 465),
(12951, 'BRC',  3, '03:20', '03:28', 8, 992),
(12951, 'BCT',  4, '08:35', NULL, 0, 1384),
(22436, 'NDLS', 1, NULL, '06:00', 0, 0),
(22436, 'BSB',  2, '14:00', NULL, 0, 759),
(12137, 'CSMT', 1, NULL, '19:35', 0, 0),
(12137, 'FZR',  2, '05:10', NULL, 0, 1926);

INSERT INTO Coaches (coach_id, train_no, coach_code, class_code, capacity) VALUES
(1, 12951, 'B1', '3A', 72),
(2, 12951, 'A1', '2A', 48),
(3, 22436, 'C1', 'CC', 78);

INSERT INTO Berths (berth_id, coach_id, berth_number, berth_type) VALUES
(1, 1, 12, 'LOWER'),
(2, 1, 4, 'LOWER'),
(3, 2, 18, 'UPPER'),
(4, 3, 22, 'LOWER');

INSERT INTO Quotas (quota_code, quota_name, description) VALUES
('GN', 'General Quota', 'Standard advance reservation'),
('TQ', 'Tatkal Quota', 'Last-minute high-concurrency quota'),
('PT', 'Premium Tatkal', 'Dynamic fare Tatkal quota'),
('LD', 'Ladies Quota', 'Reserved for female passengers'),
('SS', 'Senior Citizen', 'Lower berth concession quota');

INSERT INTO Segment_Inventory (train_no, berth_id, quota_code, journey_date, from_stop_order, to_stop_order, leg_bitmask, status, current_pnr) VALUES
(12951, 1, 'GN', date('now'), 1, 2, '100', 'BOOKED', 'PNR1000001'),
(12951, 1, 'GN', date('now'), 3, 4, '001', 'AVAILABLE', NULL),
(12951, 2, 'TQ', '2026-11-15', 1, 4, '111', 'BOOKED', 'PNR1000002');

-- Tickets (covering today, tomorrow, past 7 days, and 2026-11-15)
INSERT INTO Tickets (pnr_no, journey_date, user_id, train_no, src_station, dest_station, from_stop_order, to_stop_order, class_code, base_fare, gst_amount, total_fare, ticket_status, booking_timestamp) VALUES
('PNR1000001', date('now'), 'u-1001', 12951, 'NDLS', 'KOTA', 1, 2, '3A', 1047.62, 52.38, 1100.00, 'CONFIRMED', datetime('now', '-1 days')),
('PNR1000002', date('now'), 'u-3312-b56', 12951, 'NDLS', 'BCT', 1, 4, '3A', 1447.62, 72.38, 1520.00, 'CONFIRMED', datetime('now', '-2 days')),
('PNR1000003', '2026-11-15', 'u-4001', 12951, 'NDLS', 'BCT', 1, 4, '3A', 1047.62, 52.38, 1100.00, 'WAITLIST', datetime('now', '-3 days')),
('PNR1000004', date('now', '+1 day'), 'u-7761-c89', 22436, 'NDLS', 'BSB', 1, 2, 'CC', 1666.67, 83.33, 1750.00, 'CONFIRMED', datetime('now', '-1 days')),
('PNR1000005', '2026-11-15', 'u-7761-c89', 12951, 'NDLS', 'BCT', 1, 4, '2A', 3200.00, 160.00, 3360.00, 'CONFIRMED', datetime('now', '-2 days')),
('PNR1000006', '2026-11-15', 'u-7761-c89', 22436, 'NDLS', 'BSB', 1, 2, 'CC', 1666.67, 83.33, 1750.00, 'CONFIRMED', datetime('now', '-4 days')),
('PNR1000007', '2026-11-16', 'u-3312-b56', 12951, 'NDLS', 'BCT', 1, 4, '3A', 1047.62, 52.38, 1100.00, 'CANCELLED', datetime('now', '-5 days'));

INSERT INTO Passengers (pnr_no, journey_date, full_name, age, gender, assigned_berth_id, current_status) VALUES
('PNR1000001', date('now'), 'Aarav Sharma', 31, 'M', 1, 'CNF/B1/12 (LB)'),
('PNR1000002', date('now'), 'Pooja Hegde', 28, 'F', 2, 'CNF/B1/04 (LB)'),
('PNR1000003', '2026-11-15', 'Suresh Menon', 67, 'M', NULL, 'WL/1'),
('PNR1000004', date('now', '+1 day'), 'Kamala Devi', 64, 'F', 4, 'CNF/C1/22 (LB)'),
('PNR1000005', '2026-11-15', 'Vikram Rao', 42, 'M', 3, 'CNF/A1/18 (UB)'),
('PNR1000006', '2026-11-15', 'Neha Kapoor', 29, 'F', 4, 'CNF/C1/22 (LB)'),
('PNR1000007', '2026-11-16', 'Pooja Hegde', 28, 'F', NULL, 'CAN');

INSERT INTO Payments (transaction_id, pnr_no, journey_date, payment_mode, amount_paid, payment_status, payment_timestamp) VALUES
('TXN9001', 'PNR1000001', date('now'), 'UPI', 1100.00, 'SUCCESS', datetime('now', '-1 days')),
('TXN9002', 'PNR1000002', date('now'), 'UPI', 1520.00, 'SUCCESS', datetime('now', '-2 days')),
('TXN9003', 'PNR1000003', '2026-11-15', 'NET_BANKING', 1100.00, 'FAILED', datetime('now', '-3 days')),
('TXN9004', 'PNR1000004', date('now', '+1 day'), 'CREDIT_CARD', 1750.00, 'SUCCESS', datetime('now', '-1 days')),
('TXN9005', 'PNR1000005', '2026-11-15', 'CREDIT_CARD', 3360.00, 'FAILED', datetime('now', '-2 days')),
('TXN9006', 'PNR1000006', '2026-11-15', 'UPI', 1750.00, 'SUCCESS', datetime('now', '-4 days')),
('TXN9007', 'PNR1000007', '2026-11-16', 'UPI', 1100.00, 'REFUNDED', datetime('now', '-5 days'));

INSERT INTO Waitlist_Queue (train_no, passenger_id, journey_date, class_code, queue_position, created_at) VALUES
(12951, 3, '2026-11-15', '3A', 1, datetime('now', '-3 days'));
