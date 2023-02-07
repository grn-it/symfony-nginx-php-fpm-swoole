### Install
install:
	@make build
	@make build-nginx-swoole
	@make swoole-up
	@docker-compose -f docker-compose-swoole.yml exec symfony-web-application make install-cmd
	@docker-compose -f docker-compose-swoole.yml exec symfony-web-application make fix-permissions-for-host uid=$(shell id -u)
	@docker-compose -f docker-compose-swoole.yml exec symfony-web-application make fix-permissions-for-php-fpm

install-cmd:
	@composer install

### Permissions
fix-permissions-for-host:
	@setfacl -dR -m u:$(uid):rwX .
	@setfacl -R -m u:$(uid):rwX .
	
fix-permissions-for-php-fpm:
	@setfacl -dR -m u:$$(id -u):rwX .
	@setfacl -R -m u:$$(id -u):rwX .

### Build
build:
	@docker-compose -f docker-compose-swoole.yml -f docker-compose-php-fpm.yml build --force-rm

build-nginx-swoole:
	@docker-compose -f docker-compose-swoole.yml build -q nginx

build-nginx-php-fpm:
	@docker-compose -f docker-compose-php-fpm.yml build -q nginx

### Swoole
### may be needed "make build-nginx-swoole"
swoole-up:
	@docker-compose -f docker-compose-swoole.yml up -d
	
swoole-down:
	@docker-compose -f docker-compose-swoole.yml down

swoole-reload:
	@docker-compose -f docker-compose-swoole.yml exec symfony-web-application make swoole-reload-cmd

swoole-reload-cmd:
	@kill -USR1 $$(ps -a | grep -m1 "php -d variables_order=EGPCS public/index.php" | awk '{printf $$1}')

### PHP-FPM
### may be needed "make build-nginx-php-fpm"
php-fpm-up:
	@docker-compose -f docker-compose-php-fpm.yml up -d
	
php-fpm-down:
	@docker-compose -f docker-compose-php-fpm.yml down

### Symfony Web Application
symfony:
	@docker-compose -f docker-compose-swoole.yml exec symfony-web-application bash

### K6 Benchmarking
k6:
	@docker-compose -f docker-compose-k6.yml run k6 run -d 10s k6.js
