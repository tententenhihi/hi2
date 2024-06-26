#!/bin/bash

# Cập nhật hệ thống và cài đặt các gói cần thiết
sudo dnf update -y
sudo dnf install -y nginx python3

# Cài đặt Flask
sudo python3 -m pip install flask

# Tạo thư mục cho ứng dụng Flask
mkdir -p /opt/webhook
cd /opt/webhook

# Tạo file webhook.py
API_KEY="tentenhahaha"

cat << EOF > /opt/webhook/webhook.py
from flask import Flask, request, abort
import os

app = Flask(__name__)

API_KEY = '$API_KEY'

@app.route('/webhook/rb', methods=['POST'])
def webhook():
    if request.headers.get('x-api-key') == API_KEY:
        os.system('sudo reboot')
        return 'Rebooting...', 200
    else:
        abort(403)

if __name__ == '__main__':
        app.run(host='0.0.0.0', port=5000)
EOF

# Cấu hình Nginx
cat << EOF > /etc/nginx/conf.d/webhook.conf
server {
    listen 80;
    server_name _;

    location /webhook {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Khởi động và kích hoạt Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Tạo file dịch vụ systemd cho ứng dụng Flask
cat << EOF > /etc/systemd/system/webhook.service
[Unit]
Description=Flask Webhook Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/webhook/webhook.py
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd và khởi động dịch vụ webhook
sudo systemctl daemon-reload
sudo systemctl start webhook
sudo systemctl enable webhook

# Cấu hình quyền sudo để không cần nhập mật khẩu khi reboot
echo 'nobody ALL=(ALL) NOPASSWD: /sbin/reboot' | sudo tee -a /etc/sudoers

echo "Setup completed. Your webhook is now ready."
