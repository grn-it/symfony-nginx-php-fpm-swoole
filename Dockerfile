FROM php:8.1-alpine AS symfony-web-application
RUN apk add bash acl yq make
## Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.alpine.sh' | bash && \
    apk add symfony-cli
## PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions openswoole
## Composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV PATH $PATH:/root/.composer/vendor/bin
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR app
COPY entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
ENTRYPOINT ["entrypoint"]

## Nginx with PHP-FPM config
FROM nginx as nginx-php-fpm
COPY docker/nginx/conf.d/nginx-php-fpm.conf /etc/nginx/conf.d/default.conf
WORKDIR /app/public
CMD ["nginx", "-g", "daemon off;"]

## Nginx with Swoole config
FROM nginx as nginx-swoole
COPY docker/nginx/conf.d/nginx-swoole.conf /etc/nginx/conf.d/default.conf
WORKDIR /app/public
CMD ["nginx", "-g", "daemon off;"]

## PHP-FPM
FROM php:fpm-alpine AS php_fpm
RUN set -eux; \
	apk add --no-cache --virtual .build-deps $PHPIZE_DEPS icu-dev libzip-dev zlib-dev; \
	docker-php-ext-configure zip; \
	docker-php-ext-install -j$(nproc) intl zip; \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .phpexts-rundeps $runDeps; \
	apk del .build-deps
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY docker/php-fpm/conf.d/php.prod.ini $PHP_INI_DIR/conf.d/php.prod.ini
COPY docker/php-fpm/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
WORKDIR /app
CMD ["php-fpm"]

## K6
FROM loadimpact/k6 AS k6
WORKDIR /app
