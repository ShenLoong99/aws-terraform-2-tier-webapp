#!/bin/bash
# Install Node.js
sudo dnf install -y nodejs 

# Create the app file in the home directory
cat <<EOF > /home/ec2-user/index.js
const http = require('http');
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from Systemd managed EC2!');
}).listen(3000, '0.0.0.0');
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