#######Cài nginx#####
sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y
wget -O- https://nginx.org/keys/nginx_signing.key | gpg --dearmor     | tee /etc/apt/trusted.gpg.d/nginx.gpg > /dev/null
mkdir -m 600 /root/.gnupg
gpg --dry-run --quiet --import --import-options import-show /etc/apt/trusted.gpg.d/nginx.gpg
echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx"     | tee /etc/apt/sources.list.d/nginx.list
sudo apt update
sudo apt purge nginx nginx-common nginx-full nginx-core
sudo apt install nginx
nginx -v
systemctl enable nginx
systemctl start nginx
#######Cài nginx#####
mkdir /etc/nginx/{modules-available,modules-enabled,sites-available,sites-enabled,snippets}
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat > /etc/nginx/nginx.conf << 'EOL'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}

EOL

mkdir -p /etc/systemd/system/nginx.service.d/
echo -e "[Service]\nRestart=always\nRestartSec=10s" > /etc/systemd/system/nginx.service.d/restart.conf
systemctl daemon-reload
systemctl enable nginx
systemctl start nginx
systemctl restart nginx
cd /home
mkdir n8n.kycaz.com
#####Cấu hình domain nginx ####
sudo tee /etc/nginx/conf.d/n8n.kycaz.com.conf > /dev/null << 'EOL'
server {
    listen 80;
    listen [::]:80;
    server_name n8n.kycaz.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name n8n.kycaz.com;
    ssl_certificate /etc/nginx/ssl/n8n.kycaz.com/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/n8n.kycaz.com/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    #ssl_stapling on;
    #ssl_stapling_verify on;

    # Enable gzip compression for text-based resources
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    # CORS header settings
    #add_header Access-Control-Allow-Origin *;
    #add_header Pragma public;
    #add_header Cache-Control public;
    #add_header X-Frame-Options ALLOWALL;
	
	add_header Content-Security-Policy "frame-ancestors *";
	add_header 'Access-Control-Allow-Origin' '*';
	add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
	add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
	add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';

    # Increase the body size limit to accommodate large uploads
    client_max_body_size 15G;

	
    # Proxy settings for the application server
    location / {
	
		proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
		proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 16 64k;
        proxy_buffer_size 128k;
        client_max_body_size 10M;
        proxy_set_header X-Forwarded-Server $host;

        proxy_pass_request_headers on;
        proxy_max_temp_file_size 0;
        proxy_connect_timeout 900;
        proxy_send_timeout 900;
        proxy_read_timeout 900;

        proxy_busy_buffers_size 256k;
        proxy_temp_file_write_size 256k;
        proxy_intercept_errors on;
    }
}
EOL

#Tao thu muc SSL
sudo mkdir -p /etc/nginx/ssl/n8n.kycaz.com/
sudo tee /etc/nginx/ssl/n8n.kycaz.com/certificate.crt > /dev/null << 'EOL'

-----BEGIN CERTIFICATE-----
MIIEnjCCA4agAwIBAgIUHVBq10+4XBOA0/H/M7jlHw7ML14wDQYJKoZIhvcNAQEL
BQAwgYsxCzAJBgNVBAYTAlVTMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTQw
MgYDVQQLEytDbG91ZEZsYXJlIE9yaWdpbiBTU0wgQ2VydGlmaWNhdGUgQXV0aG9y
aXR5MRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMRMwEQYDVQQIEwpDYWxpZm9ybmlh
MB4XDTI1MDMxNDEzMjkwMFoXDTQwMDMxMDEzMjkwMFowYjEZMBcGA1UEChMQQ2xv
dWRGbGFyZSwgSW5jLjEdMBsGA1UECxMUQ2xvdWRGbGFyZSBPcmlnaW4gQ0ExJjAk
BgNVBAMTHUNsb3VkRmxhcmUgT3JpZ2luIENlcnRpZmljYXRlMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxIkdJYCUzEdQyc2uYzIZ+XGo6HhLBo0PdaDn
fuMiOpJIBY6LvBSdyTQ29BBeMTXT9C0w9G3V9KQ9Yr5S2xTmGeA/esTXMSzKTeLH
nkseTe7akPwHpmKBhOhYLpX1FEti0QzyR7O9X1K9/3XNkAdyVQBwbI/8V/wR86xd
OVR1Zr3xrrSqSYa2CXoDxh8EsYBlV2sy45Dln6qfZT8bx8DX4FkwIIuluqARvBbU
4Pg38SPmfmzybZ3hrjJMCYgBPVUO4tsXCDzQDElzibwgncT+aSrg0zzwjuNrf4A3
wbZYJlmaGrUuIyeVuV/IaW29hGpLBpPjhk/YhRFPpcUXXa/RbQIDAQABo4IBIDCC
ARwwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
ATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBSJrqvil3kP195r1D9B/LlKsAnAwDAf
BgNVHSMEGDAWgBQk6FNXXXw0QIep65TbuuEWePwppDBABggrBgEFBQcBAQQ0MDIw
MAYIKwYBBQUHMAGGJGh0dHA6Ly9vY3NwLmNsb3VkZmxhcmUuY29tL29yaWdpbl9j
YTAhBgNVHREEGjAYggsqLmt5Y2F6LmNvbYIJa3ljYXouY29tMDgGA1UdHwQxMC8w
LaAroCmGJ2h0dHA6Ly9jcmwuY2xvdWRmbGFyZS5jb20vb3JpZ2luX2NhLmNybDAN
BgkqhkiG9w0BAQsFAAOCAQEAioKoM0q9xyQ9cudWDN88S7NRZRFyKCdRkqrmxMPE
bCRpPPoOkX9DN/wKvMUGnRPDhvDUH7rC9W2CxS/C4IDWB/VU0Q22zyCO0P6+gDbI
ZVd7QiRYppb/C7xinzB4w1MWWOVSB56zXDUba2GGVpHivBFG08VDR/gzj9QWX/Mm
4MryWcPjAep1tVHgd3I0Kz7U/L0p21Hmt9ToWm3ktCZRILjzYjOuOH2U9k/548hc
phMa+39IP2D40WscKxZcU5bDAmKgVAGkD3jR+2nJTiKOvnLTQCED3Ry2cSmJTmkI
lz8cjOzpnYqmY5xLKWRi9o62EQzfHRURIafYdpMPWJ2xeg==
-----END CERTIFICATE-----
EOL
sudo tee /etc/nginx/ssl/n8n.kycaz.com/private.key > /dev/null << 'EOL'

-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDEiR0lgJTMR1DJ
za5jMhn5cajoeEsGjQ91oOd+4yI6kkgFjou8FJ3JNDb0EF4xNdP0LTD0bdX0pD1i
vlLbFOYZ4D96xNcxLMpN4seeSx5N7tqQ/AemYoGE6FgulfUUS2LRDPJHs71fUr3/
dc2QB3JVAHBsj/xX/BHzrF05VHVmvfGutKpJhrYJegPGHwSxgGVXazLjkOWfqp9l
PxvHwNfgWTAgi6W6oBG8FtTg+DfxI+Z+bPJtneGuMkwJiAE9VQ7i2xcIPNAMSXOJ
vCCdxP5pKuDTPPCO42t/gDfBtlgmWZoatS4jJ5W5X8hpbb2EaksGk+OGT9iFEU+l
xRddr9FtAgMBAAECggEAOrvlR3tdPI1FggGjT4a+B3NlsI+ekEcgqx0agaucY5eq
yWpXrS4WF3aww5COrbMx9AN7YVjfu3xH0hYhydI9j9cZ8XUZAFur28ndsRsu48hx
bim7mYhPv6n2DHoJI3cCAYqWb0IyYmXmXQ1WEOiAzRFUB8Wh+qNctA87TvJEIZ80
z+NkiMQzhHoAatamM3ecVmAu/+2g3CO0cdYDkSiMZfIcVp+kv4712wKvdD331zco
/s83N2kDaPArnyvJ4el3odfqx+RgX+zde5FrwYdAFBcqt+TUrygeLl5fRcSB9ffk
0wng8qdeIdu1jkkOvXzrVPbZw8SHd8UrwI+SG1aauwKBgQDwqv/kT79YW6KP5BXw
KAn5Gmw2eRbJ50ETg4uxbGhoji1VDJs5hpnfFhFISE0hiX4JLVhuvr/TAGxTVw/z
aDujlGDb03Z1nzUFc0woCtyokEPHAlaKz5zIqhbDFDGS3yfaFTlYQBs/wPwUKATA
wIyeKJQ3kt5JRfGvbu+w91S+xwKBgQDRDl6LsMSpv9Vc2qf02FW3J36AME2k1J5R
rSm1VEd0e+ts9YX+nTxTVtZxMbW7kPi2LSOSXCvglBGAN98mZzAnyOfFMQjUC/xu
3cG3+mjLcRB5BF9eGCXDz8pu9RxdJi3dPFpKCn31Ffo+I/QPtEiIPM5aKjGYFB5U
3tsQZQAKKwKBgQDA0oDLUAmipWiNmNTq4Wl8J+tjiYj0o0/EbrTRpmXQv3kal0sW
v/0we+HE5AjIQfy1JZugvzu5trET5MFm57BA03T3K2nRu4kjoMj3nBxHAa8MF5d3
B/g53ez2x4sgfaLUXATh7Bro7ZoKHDYSqTMA1MpL7GQkmOGXCW8JfmBrqQKBgCVV
o5ze3MBT+g6zHfukBurGqtjJx5QARKXhfulbO8eZudmjn2JxQiy//VwJvKLaqRAf
z5J703ov91Amqjt5gigYwQt+Tk1QNqy1/bqVhdGPR5nVJhLvzQ7DNSvLql0YTGiO
NrGyXfw/CInAcf27/JgYA+ImVuUJ8sDFa+npn7AxAoGAXAAT9YbIMyDvohdD7+oA
F20xItJoFaX28k94lvYhyXKHBH5Y3ZZ8yW9iwxeevX1PV8Pz3sfrByUaBoSsfyhL
i1aJ3/o+DoavO90md5o1EfR/uVk0ZSJZN02ciOlYbaNBSvfecSxjMOioNvXASKIl
qwNeYd2j+52K/xugECw3aXk=
-----END PRIVATE KEY-----

EOL
systemctl daemon-reload
systemctl restart nginx
service nginx restart
# Khởi động lại dịch vụ Nginx để áp dụng cấu hình
systemctl restart nginx
cd /home/n8n.kycaz.com
# Khởi động lại dịch vụ Nginx để áp dụng cấu hình
systemctl restart nginx
# Cập nhật danh sách gói và cài đặt software-properties-common
sudo apt update
sudo apt install software-properties-common

#Cài mout ổ đĩa
sudo apt-get install nginx cifs-utils -y
sudo service nginx restart
cd /home/n8n.kycaz.com

mkdir -p /home/n8n.kycaz.com/{data,config}
sudo chown -R 1000:1000 /home/n8n.kycaz.com/*

###### CÀI POSTGRESQL ######
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Yêu cầu nhập thông tin PostgreSQL
read -p "Nhập tên user PostgreSQL (mặc định: n8n_user): " db_user
db_user=${db_user:-n8n_user}

read -sp "Nhập mật khẩu PostgreSQL (mặc định: n8n_pass): " db_password
db_password=${db_password:-n8n_pass}
echo

read -p "Nhập tên database (mặc định: n8n_db): " db_name
db_name=${db_name:-n8n_db}

# Tạo user và database
sudo -u postgres psql <<EOF
CREATE USER ${db_user} WITH PASSWORD '${db_password}';
CREATE DATABASE ${db_name} OWNER ${db_user};
ALTER USER ${db_user} WITH SUPERUSER;
EOF

# Cho phép remote access
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/*/main/postgresql.conf
sudo systemctl restart postgresql
###### END POSTGRESQL ######

mkdir -p /home/n8n.kycaz.com/{data,config}
sudo chown -R 1000:1000 /home/n8n.kycaz.com/*

sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker

###### ... (Phần cài đặt Nginx và các bước khác giữ nguyên) ######

# Lấy IP của host machine
read -p "Vui lòng nhập IP của VPS (ví dụ: 128.140.86.132): " host_ip
while [[ -z "$host_ip" ]]; do
    echo "Bạn chưa nhập IP! Vui lòng thử lại."
    read -p "Nhập IP của VPS: " host_ip
done

# Chạy container với thông tin đã nhập
docker run -d \
  --name n8n \
  -p 127.0.0.1:5678:5678 \
  -v /home/n8n.kycaz.com/data:/home/node/.n8n \
  -v /home/n8n.kycaz.com/config:/config \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST="$host_ip" \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_USER="${db_user}" \
  -e DB_POSTGRESDB_PASSWORD="${db_password}" \
  -e DB_POSTGRESDB_DATABASE="${db_name}" \
  -e DB_POSTGRESDB_CONNECTION_TIMEOUT=60000 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=Admin \
  -e N8N_BASIC_AUTH_PASSWORD=834435 \
  n8nio/n8n

echo "Container n8n đã được khởi chạy với:"
echo "- User PostgreSQL: ${db_user}"
echo "- Database: ${db_name}"
echo "- IP VPS: ${host_ip}"
  
