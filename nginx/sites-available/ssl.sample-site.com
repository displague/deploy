## Sample server {} block directives for SSL/HTTPS

server {
	listen   80; ## listen for ipv4; this line is default and implied

	# Make site accessible from world wide
	server_name ssl.sample-site.com;
	rewrite	^ https://$server_name$request_uri? permanent;

	root /home/masedi/ssl.sample-site.com;
	index index.php index.html index.htm;

    # Logging setting.
	access_log /var/log/nginx/ssl.sample-site.com.access.log;
	error_log  /var/log/nginx/ssl.sample-site.com.error.log;

	## Global directives configuration.
    include /etc/nginx/conf.vhost/block.conf;
	include /etc/nginx/conf.vhost/staticfiles.conf;
	include /etc/nginx/conf.vhost/restrictions.conf;

	location / {
		# Enables directory listings when index file not found.
		autoindex  on;

		# Shows file listing times as local time.
		autoindex_localtime on;

		try_files $uri $uri/ /index.php?$args;
	}

	# pass the PHP scripts to FastCGI server listening on unix socket
	#
	location ~ \.php$ {
		try_files $uri =404;

		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		#NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

		fastcgi_index index.php;
		fastcgi_pass unix:/var/run/php5-fpm.masedi.sock;

		# Include FastCGI Params.
		include /etc/nginx/fastcgi_params;

		# Overwrite FastCGI Params here. Test only, params should be added to fastcgi_params.
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param SCRIPT_NAME     $fastcgi_script_name;

		# Include FastCGI Configs.
		include /etc/nginx/conf.vhost/fastcgi.conf;

		# Uncomment to Enable PHP FastCGI cache.
		include /etc/nginx/conf.vhost/fastcgi_cache.conf;
	}

    # redirect server error pages to the static page /50x.html
    #
    #error_page 500 502 503 504 /50x.html;
    #location = /50x.html {
    #   root /usr/share/nginx/www;
    #}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	#location ~ /\.ht {
	#	deny all;
	#}
}

## SSL configuration

server {
	listen 443;
	server_name ssl.sample-site.com;

	ssl on;
	ssl_certificate /etc/nginx/ssl/ssl.sample-site.com/ssl.sample-site.com.crt;
	ssl_certificate_key /etc/nginx/ssl/ssl.sample-site.com/ssl.sample-site.com.key;
	ssl_session_timeout 5m;
	ssl_prefer_server_ciphers on;
	# Enables SSLv3/TLSv1, but not SSLv2 which is weak and should no longer be used.
	ssl_protocols SSLv3 TLSv1;
	# Disables all weak ciphers
	ssl_ciphers ALL:!aNULL:!ADH:!eNULL:!LOW:!EXP:RC4+RSA:+HIGH:+MEDIUM;

	root /home/masedi/ssl.sample-site.com/;
	index index.php index.html index.htm;

    # Logging setting.
	access_log   /var/log/nginx/ssl.sample-site.com.access.log;
	error_log	/var/log/nginx/ssl.sample-site.com.error.log;

	## Global directives configuration.
	include /etc/nginx/conf.vhost/block.conf;
	include /etc/nginx/conf.vhost/staticfiles.conf;
	include /etc/nginx/conf.vhost/restrictions.conf;

	location / {
        # Enables directory listings when index file not found.
        autoindex  on;

        # Shows file listing times as local time.
        autoindex_localtime on;

		# First attempt to serve request as file, then
		# as directory, then fall back to index.html
		try_files $uri $uri/ /index.php?$args;

		# Uncomment to enable naxsi on this location
		# include /etc/nginx/naxsi.rules
	}

    # pass the PHP scripts to FastCGI server listening on unix socket
    #
    location ~ \.php$ {
        try_files $uri =404;

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

        fastcgi_index index.php;
        fastcgi_pass unix:/var/run/php5-fpm.masedi.sock;

        # Include FastCGI Params.
        include /etc/nginx/fastcgi_params;

        # Overwrite FastCGI Params here. Test only, params should be added to fastcgi_params.
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME     $fastcgi_script_name;

        # Include FastCGI Configs.
        include /etc/nginx/conf.vhost/fastcgi.conf;

        # Uncomment to Enable PHP FastCGI cache.
        include /etc/nginx/conf.vhost/fastcgi_cache.conf;
    }

}