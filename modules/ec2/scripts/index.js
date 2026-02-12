require("dotenv").config();
const express = require("express");
const mysql = require("mysql2");
const bodyParser = require("body-parser");
const os = require("os");

const app = express();
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
// This tells Express to serve files from the 'assets' directory
app.use("/assets", express.json(), express.static("/home/ec2-user/app/assets"));

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

// Handle connection errors so the app doesn't crash if RDS is slow to respond
db.on("error", (err) => {
  console.error("Database error:", err);
});

// Robust Initialization: Step 1 - Create table
db.query(
  `CREATE TABLE IF NOT EXISTS items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    completed TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)`,
  (err) => {
    if (err) return console.error("Table Init Error:", err);

    // Step 2 - Add 'completed' column if it's missing (Version-safe way)
    db.query(`SHOW COLUMNS FROM items LIKE 'completed'`, (err, rows) => {
      if (!err && rows.length === 0) {
        db.query(`ALTER TABLE items ADD COLUMN completed TINYINT(1) DEFAULT 0`);
      }
    });
  },
);

const getLayout = () => {
  let html = "<!DOCTYPE html><html><head><title>To Do List</title>";
  html += '<link rel="icon" type="image/png" href="/assets/favicon.ico">';
  html +=
    '<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">';
  html +=
    '<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">';
  html +=
    "<style>.completed-task { text-decoration: line-through; color: #adb5bd; font-style: italic; } .card { border-radius: 15px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); border:none; } .task-row { transition: all 0.2s; } .task-row:hover { background-color: #f8f9fa; }</style></head>";
  html +=
    '<body class="bg-light"><nav class="navbar navbar-dark bg-dark mb-4 p-3"><div class="container"><span class="navbar-brand fw-bold">🚀 To Do List</span></div></nav>';
  html +=
    '<div class="container"><div class="row justify-content-center"><div class="col-md-8"><div class="card p-4">';
  html += '<h4 class="mb-4">To Do List</h4><div class="input-group mb-4">';
  html +=
    '<input type="text" id="taskInput" class="form-control" placeholder="What needs to be done?">';
  html +=
    '<button onclick="addTask()" class="btn btn-primary px-4"><i class="bi bi-plus-lg"></i></button></div>';
  html +=
    '<div id="taskList"><p class="text-center text-muted">Loading tasks...</p></div></div>';
  html +=
    '<p class="text-center text-muted mt-3 small">Server ID: ' +
    os.hostname() +
    "</p></div></div></div>";

  html += "<script>";
  html += "async function loadTasks() {";
  html += "  try {";
  html +=
    '    const res = await fetch("/api/tasks"); const tasks = await res.json();';
  html += '    const list = document.getElementById("taskList");';
  html +=
    "    if (tasks.length === 0) { list.innerHTML = \"<p class='text-center text-muted py-3'>No tasks yet!</p>\"; return; }";
  html += "    list.innerHTML = tasks.map(function(t) {";
  html += '      var cls = t.completed ? "completed-task" : "";';
  html +=
    "      var btn = !t.completed ? \"<button onclick='doneTask(\" + t.id + \")' class='btn btn-sm btn-success me-2'><i class='bi bi-check-lg'></i></button>\" : \"\";";
  html +=
    "      return \"<div class='d-flex justify-content-between align-items-center border-bottom py-3 task-row'>\" +";
  html +=
    '             "<span class=\'fs-5 ms-2 " + cls + "\'>" + t.name + "</span>" +';
  html +=
    "             \"<div class='me-2'>\" + btn + \"<button onclick='deleteTask(\" + t.id + \")' class='btn btn-sm btn-outline-danger'><i class='bi bi-trash'></i></button></div></div>\";";
  html += '    }).join("");';
  html += '  } catch (e) { console.error("Load failed", e); }';
  html += "}";
  html +=
    'async function addTask() { const input = document.getElementById("taskInput"); if(!input.value) return; await fetch("/api/tasks", {method:"POST", headers:{"Content-Type":"application/json"}, body:JSON.stringify({name:input.value})}); input.value=""; loadTasks(); }';
  html +=
    'async function doneTask(id) { await fetch("/api/tasks/complete/" + id, {method:"PUT"}); loadTasks(); }';
  html +=
    'async function deleteTask(id) { if(!confirm("Delete this task?")) return; await fetch("/api/tasks/" + id, {method:"DELETE"}); loadTasks(); }';
  html += "loadTasks();";
  html += "</script></body></html>";

  return html;
};

app.get("/", (req, res) => res.send(getLayout()));

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

app.get("/api/tasks", (req, res) => {
  db.query(
    "SELECT * FROM items ORDER BY completed ASC, id DESC",
    (err, results) => {
      if (err) return res.status(500).json([]);
      res.json(results);
    },
  );
});

app.post("/api/tasks", (req, res) => {
  db.query("INSERT INTO items (name) VALUES (?)", [req.body.name], () =>
    res.sendStatus(201),
  );
});

app.put("/api/tasks/complete/:id", (req, res) => {
  db.query("UPDATE items SET completed = 1 WHERE id = ?", [req.params.id], () =>
    res.sendStatus(200),
  );
});

app.delete("/api/tasks/:id", (req, res) => {
  db.query("DELETE FROM items WHERE id = ?", [req.params.id], () =>
    res.sendStatus(200),
  );
});

const server = app.listen(3000, () => {
  console.log("Server is running");
});

// These MUST be larger than the ALB Idle Timeout (default 60s)
server.keepAliveTimeout = 65000;
server.headersTimeout = 66000;
