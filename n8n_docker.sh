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


#mail {
#	# See sample authentication script at:
#	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
# 
#	# auth_http localhost/auth.php;
#	# pop3_capabilities "TOP" "USER";
#	# imap_capabilities "IMAP4rev1" "UIDPLUS";
# 
#	server {
#		listen     localhost:110;
#		protocol   pop3;
#		proxy      on;
#	}
# 
#	server {
#		listen     localhost:143;
#		protocol   imap;
#		proxy      on;
#	}
#}

EOL

nginx -t
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


sudo apt update

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install docker-ce -y

sudo apt update
sudo apt install -y docker-compose-plugin

#sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

#sudo chmod +x /usr/local/bin/docker-compose

sudo systemctl start docker
sudo systemctl enable docker
sleep 5

sudo tee /home/n8n.kycaz.com/docker-compose.yml > /dev/null << 'EOL'
services:
  postgres:
    image: postgres:latest
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n_zen
      POSTGRES_PASSWORD: n8n_pass
      POSTGRES_DB: n8n_db
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=Admin
      - N8N_BASIC_AUTH_PASSWORD=zendeptrai
      - N8N_HOST=n8n.kycaz.com
      - WEBHOOK_URL=https://n8n.kycaz.com/
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n_db
      - DB_POSTGRESDB_USER=n8n_zen
      - DB_POSTGRESDB_PASSWORD=n8n_pass
    depends_on:
      - postgres
    volumes:
      - ./n8n_data:/home/node/.n8n
EOL
