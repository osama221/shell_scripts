#!/bin/bash

####################
# welcome message  #
####################



echo "hello $USER this is the magic works please enter the company name"

read name 
echo "thank u we will now create the following files for $name"


########################
# setting up the files #
########################
domain=$name.zisoftonline.com

file=/etc/nginx/sites-available/$domain

if [ ! -f $file ]; then 

#mv  /etc/nginx/sites-available/default /home/$USER

#rm /etc/nginx/sites-enabled/default

#################################################################################
#this line to copy the configurations we use always for every site nginx we only#
#have to modify the server name inside and ports numbers as we want.            #
################################################################################
cp ~/mainrepo/temp /etc/nginx/sites-available/$domain ## we need to modify this one here


###
#generating ssl by certbot

#apt install snap -y

systemctl stop nginx.service

snap install certbot --classic

certbot certonly --standalone -d $domain

systemctl start nginx.service

##the template

cat <<EOF>> /etc/nginx/sites-available/$domain


server {

    server_name  $domain;
    listen 443 ssl http2;
    http2_push_preload on;

############################
# SSL Files [ Cert / Key ] #
############################

#    ssl on;
    ssl_session_timeout 1d;
    ssl_certificate   /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/$domain/privkey.pem;

##################
# Enable TLS 1.2 #
##################

    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES1$
    ssl_prefer_server_ciphers on;
    server_tokens off;

##############
# Nginx logs #
##############

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

############################
# Application Bypass Proxy #
############################

    location / {

        proxy_connect_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_read_timeout 3600s;
        proxy_hide_header Server;
        proxy_hide_header X-Powered-By;
        proxy_buffers 16 64k;
        proxy_buffer_size 128k;
        client_max_body_size 20M;
        proxy_pass https://127.0.0.1:21001;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for";
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header X-Real-IP Secure_IP;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_redirect off;
        proxy_set_header X-Powered-By: Zisoft_Awarness;

    }



#####################################
# Block Unused HTTP Request Methods #
#####################################

    if (\$request_method !~ ^(GET|HEAD|POST|DELETE|PUT|PATCH)$ )
    {
        return 405;
    }

########################
# Compress Config Gzip  #
#########################

    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types
        text/css
        text/javascript
        text/xml
        text/plain
        image/bmp
        image/gif
        image/jpeg
        image/jpg
        image/png
        image/svg+xml
        image/x-icon
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-javascript
        application/xml


###################################
# Block Unauthorized Access to .mp4 #
#####################################



    location /meta/embed {
        if (\$http_referer !~* "app|admin")
            {
            return 401;
            }
        proxy_pass https://127.0.0.1:21001;
        }




    location ~* (.+\.(mp4))$ {
        if (\$http_referer !~* "lesson|index")
            {
            return 401;
            }
        proxy_pass https://127.0.0.1:21001;
        }
    }

##########################
# Redirect HTTP to HTTPS #
##########################

    server {
        if (\$host = $domain) {
            return 301 https://\$host$request_uri;
        }

    listen 80;
    server_name  $domain;
        return 404;
    }

EOF



ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled

mkdir /deployment/$name

fi

##############
#here we begin the code for refreshing the stack if exists
##############
echo "the company name files are already exists we will remove the stack and rebuild the project "

sleep 15

sudo apt-get update

sudo apt upgrade -y

#sudo apt install php php-common php-cli php-gd php-curl php-mysql php-xml php-mbstring -y

#sudo apt remove "php*" --purge -y

#sudo apt remove "apache2" --purge -y

#sudo apt autoremove -y

docker stack rm $name

cd /deployment/$name/

rm -rf awareness

git clone https://awar:DkPiq8rY9Ffxihf-s8fF@gitlab.com/zisoft/awareness.git

sleep 10s

cd /deployment/$name/awareness

rm -rf /deployment/$name/awareness/.env

rm -rf /deployment/$name/awareness/storage/database

cp -vr ~/mainrepo/database/ /deployment/$name/awareness/storage/

cp -vr ~/mainrepo/basicconf.yml  /deployment/$name/awareness/

cp -vr ~/mainrepo/.env  /deployment/$name/awareness/

cp -vr /template/videos  /deployment/$name/awareness/public/

cd /deployment/$name/awareness

chmod -R 777 /deployment/$name/awareness/storage/framework/

chmod -R 777 /deployment/$name/awareness/storage/logs/

chmod -R 777 /deployment/$name/awareness/public/videos

chmod -R 777 /deployment/$name/awareness/public/fonts

chmod -R 777 /deployment/$name/awareness/public/uploads

chmod -R 755 /deployment/$name/awareness/metabase

chmod -R 777 /deployment/$name/awareness/public/temp_reports

chmod -R 777 /deployment/$name/awareness/public/

cd /deployment/$name/awareness

zisoft build --docker  --ui --composer --prod

docker stack deploy -c 'basicconf.yml' $name

sleep 20s

docker service ls | grep $name

docker ps | grep $name

#lynx 
