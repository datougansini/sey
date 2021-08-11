apt update
apt install git unzip docker-compose -y
curl -fsSL https://get.docker.com | bash -s docker
systemctl start docker
systemctl enable docker

mkdir /root/web
cd /root/web
git clone https://github.com/v2board/v2board-docker.git ./

cd /root/web/www
git clone https://newexglobal1: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@github.com/newexglobal1/newex-backend.git ./
wget https://getcomposer.org/download/2.0.13/composer.phar

cd /root/web/www/public
wget https://github.com/kalcaddle/KodExplorer/archive/refs/tags/4.46.zip
unzip 4.46.zip
mv KodExplorer-4.46 expr

(cat <<-EOF
http://0.0.0.0 {
    root /www/public
    log /wwwlogs/caddy.log
    fastcgi / /tmp/php-cgi.sock php
    rewrite {
        to {path} {path}/ /index.php?{query}
    }
}
EOF
) > /root/web/caddy.conf

(cat <<-EOF
version: '3'
services:
  www:
    image: tokumeikoi/lcrp
    volumes:
      - './www:/www'
      - './wwwlogs:/wwwlogs'
      - './caddy.conf:/run/caddy/caddy.conf'
      - './supervisord.conf:/run/supervisor/supervisord.conf'
      - './crontabs.conf:/etc/crontabs/root'
      - './.caddy:/root/.caddy'
    ports:
      - '80:80'
      - '443:443'
    restart: always
  mysql:
    image: mysql:5.7.29
    volumes:
      - './mysql:/var/lib/mysql'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: qwepoi123
      MYSQL_DATABASE: newex
EOF
) > /root/web/docker-compose.yaml

(cat <<-EOF
[program:newexglobal_1]
process_name=%(program_name)s_%(process_num)02d
command=php /www/artisan queue:work --queue=send_email
stdout_logfile=/wwwlogs/queue.log
stdout_logfile_maxbytes=0
stderr_logfile=/wwwlogs/queue_error.log
stderr_logfile_maxbytes=0
autostart=true
autorestart=true
startretries=0
numprocs=4

[program:newexglobal_2]
process_name=%(program_name)s_%(process_num)02d
command=php /www/artisan check:order
stdout_logfile=/wwwlogs/queue.log
stdout_logfile_maxbytes=0
stderr_logfile=/wwwlogs/queue_error.log
stderr_logfile_maxbytes=0
autostart=true
autorestart=true
startretries=0
numprocs=1

[program:newexglobal_3]
process_name=%(program_name)s_%(process_num)02d
command=php /www/artisan check:data
stdout_logfile=/wwwlogs/queue.log
stdout_logfile_maxbytes=0
stderr_logfile=/wwwlogs/queue_error.log
stderr_logfile_maxbytes=0
autostart=true
autorestart=true
startretries=0
numprocs=1
EOF
) > /root/web/supervisord.conf

(cat <<-EOF
APP_NAME=Newex
APP_ENV=local
APP_KEY=base64:2Yw6KlmR3burB7p9JVhK4tcIfeVSM2Pn+ZlAm3KilLc=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=newex
DB_USERNAME=root
DB_PASSWORD=qwepoi123

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_DB=1

MAIL_DRIVER=smtp
MAIL_HOST=smtpdm.aliyun.com
MAIL_PORT=80
MAIL_USERNAME=support@mail.newex.pw
MAIL_PASSWORD=jfadxsB8Uk7ajF5
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=support@mail.newex.pw
MAIL_FROM_NAME=support@mail.newex.pw
MAILGUN_DOMAIN=
MAILGUN_SECRET=

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

MIX_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
MIX_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"

EOF
) > /root/web/www/.env

cd /root/web
docker-compose up -d
docker exec -it web_www_1 php composer.phar install -vvv
docker exec -it web_www_1 php artisan config:cache