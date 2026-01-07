#!/bin/bash
# Install Node.js
sudo dnf install -y nodejs 

# Create the app file in the home directory
cat <<EOF > /home/ec2-user/index.js
const http = require('http');
const os = require('os');

const html = \`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web App 2-Tier</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .hero { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 100px 0; }
    </style>
</head>
<body>
    <nav class="navbar navbar-dark bg-dark">
        <div class="container"><a class="navbar-brand" href="#">CloudApp v1.0</a></div>
    </nav>
    <header class="hero text-center">
        <div class="container">
            <h1 class="display-3 fw-bold">Infrastructure is Live!</h1>
            <p class="lead">Your 2-tier architecture is successfully provisioned and running.</p>
            <span class="badge bg-light text-dark p-2">Server Hostname: \${os.hostname()}</span>
        </div>
    </header>
    <main class="container my-5 text-center">
        <div class="card shadow-sm p-4">
            <h3>Backend Status: <span class="text-success">Online</span></h3>
            <p>Traffic is being balanced by your AWS ALB across multiple availability zones.</p>
        </div>
    </main>
</body>
</html>\`;

http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(html);
}).listen(3000);
EOF

# Ensure ec2-user owns the file
chown ec2-user:ec2-user /home/ec2-user/index.js

# Create the Systemd Service file
sudo cat <<EOF > /etc/systemd/system/nodeserver.service
[Unit]
Description=Node.js App
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user
ExecStart=/usr/bin/node /home/ec2-user/index.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable nodeserver
sudo systemctl start nodeserver