"""
Simple Railway Reservation System (RRS) Login & Backend Database Demo
Uses Python's built-in http.server + sqlite3 connected to railway_reservation_system.db.

Run:
    python3 login_app.py
Then open:
    http://127.0.0.1:8080
"""

import html
import os
import sqlite3
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "railway_reservation_system.db")
PORT = 8080

BASE_CSS = """
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; }
  body { background: #F1F5F9; color: #0F172A; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 28px; }
  .card { background: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 14px; box-shadow: 0 10px 25px rgba(15, 23, 42, 0.08); width: 100%; max-width: 920px; overflow: hidden; }
  .header { background: #0F172A; color: #FFFFFF; padding: 22px 28px; display: flex; justify-content: space-between; align-items: center; border-bottom: 4px solid #2563EB; }
  .header h1 { font-size: 20px; font-weight: 700; }
  .header span { font-size: 12px; color: #93C5FD; font-weight: 600; background: #1E293B; padding: 5px 12px; border-radius: 999px; }
  .body { padding: 28px; }
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
  label { display: block; font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 6px; }
  input { width: 100%; padding: 10px 12px; border: 1px solid #CBD5E1; border-radius: 8px; font-size: 14px; margin-bottom: 16px; }
  input:focus { outline: none; border-color: #2563EB; box-shadow: 0 0 0 3px rgba(37,99,235,0.15); }
  button { width: 100%; background: #2563EB; color: #FFFFFF; border: none; padding: 12px; border-radius: 8px; font-size: 14px; font-weight: 700; cursor: pointer; }
  button:hover { background: #1D4ED8; }
  .hint { background: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 8px; padding: 14px; font-size: 13px; color: #1E3A8A; }
  .hint code { background: #DBEAFE; padding: 2px 6px; border-radius: 4px; font-family: "Courier New", monospace; font-weight: 700; }
  .sql-box { background: #0F172A; color: #E2E8F0; border-radius: 8px; padding: 14px 16px; font-family: "Courier New", monospace; font-size: 12.5px; line-height: 1.5; overflow-x: auto; margin-top: 10px; }
  .sql-box .kw { color: #93C5FD; font-weight: bold; }
  .error { background: #FFF1F2; border: 1px solid #FDA4AF; color: #9F1239; padding: 12px 14px; border-radius: 8px; font-size: 13px; font-weight: 600; margin-bottom: 16px; }
  .success { background: #ECFDF5; border: 1px solid #6EE7B7; color: #065F46; padding: 12px 14px; border-radius: 8px; font-size: 13px; font-weight: 600; margin-bottom: 18px; }
  table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
  th { background: #0F172A; color: #FFFFFF; text-align: left; padding: 9px 12px; font-weight: 600; }
  td { padding: 9px 12px; border-bottom: 1px solid #E2E8F0; color: #334155; }
  tr:nth-child(even) td { background: #F8FAFC; }
  .section-title { font-size: 14px; font-weight: 700; color: #0F172A; margin: 18px 0 6px; }
  .badge { display: inline-block; padding: 3px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; background: #D1FAE5; color: #065F46; }
  .logout { display: inline-block; margin-top: 16px; color: #2563EB; text-decoration: none; font-size: 13px; font-weight: 600; }
"""


def render_login_page(error_msg="", prefill_email="", prefill_uid=""):
    err_html = f'<div class="error">Authentication Failed: {html.escape(error_msg)}</div>' if error_msg else ""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RRS Login — Backend Database Demo</title>
  <style>{BASE_CSS}</style>
</head>
<body>
  <div class="card" style="max-width: 820px;">
    <div class="header">
      <h1>Railway Reservation System — Passenger Login</h1>
      <span>SQLite Backend Connected</span>
    </div>
    <div class="body grid-2">
      <div>
        {err_html}
        <form method="POST" action="/login">
          <label for="email">Registered Email (Users.email)</label>
          <input type="text" id="email" name="email" placeholder="e.g. aarav.sharma@rail.in" value="{html.escape(prefill_email)}" required>
          <label for="user_id">User ID / Access Key (Users.user_id)</label>
          <input type="password" id="user_id" name="user_id" placeholder="e.g. u-1001" value="{html.escape(prefill_uid)}" required>
          <button type="submit">Sign In &amp; Query Database</button>
        </form>
        <div class="hint" style="margin-top: 16px;">
          <strong>Demo Credentials (from <code>Users</code> table):</strong><br>
          Email: <code>aarav.sharma@rail.in</code> &nbsp;|&nbsp; User ID: <code>u-1001</code><br>
          Email: <code>pooja.h@rail.in</code> &nbsp;|&nbsp; User ID: <code>u-3312-b56</code>
        </div>
      </div>
      <div>
        <div class="section-title" style="margin-top:0;">How Backend Authentication Works</div>
        <p style="font-size: 13px; color: #475569; line-height: 1.55;">
          When you click <strong>Sign In</strong>, the Python backend opens
          <code>railway_reservation_system.db</code> and runs a parameterized SQL query against the
          <strong>Users</strong> table. If a matching row is found, it joins <strong>Tickets</strong>,
          <strong>Trains</strong>, <strong>Passengers</strong>, and <strong>Payments</strong> via Foreign Keys.
        </p>
        <div class="sql-box">
<span class="kw">SELECT</span> user_id, full_name, email, phone_number<br>
<span class="kw">FROM</span> Users<br>
<span class="kw">WHERE</span> email = ? <span class="kw">AND</span> user_id = ?;
        </div>
      </div>
    </div>
  </div>
</body>
</html>"""


def render_dashboard(user, tickets):
    rows_html = ""
    for t in tickets:
        rows_html += (
            f"<tr>"
            f"<td><strong>{html.escape(str(t[0]))}</strong></td>"
            f"<td>{html.escape(str(t[1]))} ({html.escape(str(t[2]))})</td>"
            f"<td>{html.escape(str(t[3]))} &rarr; {html.escape(str(t[4]))}</td>"
            f"<td>{html.escape(str(t[5]))}</td>"
            f"<td>{html.escape(str(t[6]))}</td>"
            f"<td>&#8377; {t[7]:.2f}</td>"
            f"<td><span class='badge'>{html.escape(str(t[8]))}</span></td>"
            f"<td>{html.escape(str(t[9]))} ({html.escape(str(t[10]))})</td>"
            f"</tr>"
        )
    if not rows_html:
        rows_html = "<tr><td colspan='8'>No bookings found for this user.</td></tr>"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RRS Dashboard — Authenticated Backend View</title>
  <style>{BASE_CSS}</style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>Welcome, {html.escape(user[1])}</h1>
      <span>Authenticated: {html.escape(user[0])}</span>
    </div>
    <div class="body">
      <div class="success">
        Database Login Verified! Matched 1 row in <strong>Users</strong> table and fetched {len(tickets)} linked booking(s) via Foreign Keys.
      </div>

      <div class="section-title">1. Authenticated User Record (<code>Users</code> Table)</div>
      <table>
        <tr><th>user_id (PK)</th><th>full_name</th><th>email (UK)</th><th>phone_number (UK)</th></tr>
        <tr>
          <td><strong>{html.escape(user[0])}</strong></td>
          <td>{html.escape(user[1])}</td>
          <td>{html.escape(user[2])}</td>
          <td>{html.escape(user[3])}</td>
        </tr>
      </table>

      <div class="section-title">2. Live Joined Bookings (<code>Tickets &bowtie; Trains &bowtie; Passengers &bowtie; Payments</code>)</div>
      <table>
        <tr>
          <th>PNR</th><th>Train</th><th>Route</th><th>Date</th>
          <th>Passenger</th><th>Fare</th><th>Status</th><th>Payment</th>
        </tr>
        {rows_html}
      </table>

      <div class="section-title">3. SQL Query Executed by Backend</div>
      <div class="sql-box">
<span class="kw">SELECT</span> t.pnr_no, t.train_no, tr.train_name, t.src_station, t.dest_station,<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;t.journey_date, p.full_name, t.total_fare, t.ticket_status, pay.payment_mode, pay.payment_status<br>
<span class="kw">FROM</span> Tickets t<br>
<span class="kw">JOIN</span> Trains tr <span class="kw">ON</span> t.train_no = tr.train_no<br>
<span class="kw">JOIN</span> Passengers p <span class="kw">ON</span> t.pnr_no = p.pnr_no <span class="kw">AND</span> t.journey_date = p.journey_date<br>
<span class="kw">LEFT JOIN</span> Payments pay <span class="kw">ON</span> t.pnr_no = pay.pnr_no <span class="kw">AND</span> t.journey_date = pay.journey_date<br>
<span class="kw">WHERE</span> t.user_id = '{html.escape(user[0])}';
      </div>

      <a class="logout" href="/">&larr; Back to Login Page</a>
    </div>
  </div>
</body>
</html>"""


class RRSHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)
        if parsed.path == "/login-check":
            email = qs.get("email", [""])[0].strip()
            uid = qs.get("user_id", [""])[0].strip()
            self._handle_auth(email, uid)
            return
        self._send_html(render_login_page())

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8")
        params = urllib.parse.parse_qs(body)
        email = params.get("email", [""])[0].strip()
        uid = params.get("user_id", [""])[0].strip()
        self._handle_auth(email, uid)

    def _handle_auth(self, email, uid):
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        cur.execute(
            "SELECT user_id, full_name, email, phone_number FROM Users WHERE email = ? AND user_id = ?",
            (email, uid),
        )
        user = cur.fetchone()
        if not user:
            conn.close()
            self._send_html(
                render_login_page(
                    error_msg=f"No matching user found for email='{email}' and user_id='{uid}'.",
                    prefill_email=email,
                    prefill_uid=uid,
                )
            )
            return

        cur.execute(
            """
            SELECT t.pnr_no, t.train_no, tr.train_name, t.src_station, t.dest_station,
                   t.journey_date, p.full_name, t.total_fare, t.ticket_status,
                   COALESCE(pay.payment_mode, 'N/A'), COALESCE(pay.payment_status, 'N/A')
            FROM Tickets t
            JOIN Trains tr ON t.train_no = tr.train_no
            JOIN Passengers p ON t.pnr_no = p.pnr_no AND t.journey_date = p.journey_date
            LEFT JOIN Payments pay ON t.pnr_no = pay.pnr_no AND t.journey_date = pay.journey_date
            WHERE t.user_id = ?
            ORDER BY t.journey_date DESC
            """,
            (user[0],),
        )
        tickets = cur.fetchall()
        conn.close()
        self._send_html(render_dashboard(user, tickets))

    def _send_html(self, content):
        data = content.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    print(f"Starting RRS Login App on http://127.0.0.1:{PORT}")
    print(f"Connected to DB: {DB_PATH}")
    HTTPServer(("127.0.0.1", PORT), RRSHandler).serve_forever()
