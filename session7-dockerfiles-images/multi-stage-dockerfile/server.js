const express = require("express");

const app = express();
const PORT = 8080;

app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Docker Multi-Stage Build</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
          background: #0f172a;
          color: #f8fafc;
        }
        .card {
          background: #1e293b;
          padding: 40px 50px;
          border-radius: 16px;
          box-shadow: 0 10px 30px rgba(0,0,0,0.5);
          text-align: center;
          border: 1px solid #38bdf8;
        }
        h1 {
          color: #38bdf8;
          font-size: 28px;
          margin-bottom: 12px;
        }
        p {
          color: #94a3b8;
          font-size: 16px;
        }
        .badge {
          display: inline-block;
          margin-top: 15px;
          padding: 6px 14px;
          background: #0369a1;
          color: #e0f2fe;
          border-radius: 20px;
          font-size: 14px;
          font-weight: 600;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Hello World from Docker multi-stage build</h1>
        <p>Production image compiled and packaged via Multi-Stage Dockerfile</p>
        <div class="badge">Running on Port 8080</div>
      </div>
    </body>
    </html>
  `);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running and listening on port ${PORT}`);
});
