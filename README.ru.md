# Docker + nginx-proxy + Let's Encrypt

Автоматический обратный прокси с бесплатными SSL-сертификатами от Let's Encrypt.

[English version](README.md)

## Описание

Проект предназначен для быстрого развертывания nginx в качестве обратного прокси с автоматическим получением и обновлением SSL-сертификатов от Let's Encrypt. Подходит для микросервисной архитектуры на новой машине или для работы рядом с Apache.

**Не устанавливайте на сервер, где уже заняты порты 80/443** -- будет конфликт.

## Требования

- Docker
- Docker Compose

## Быстрый старт

### 1. Клонировать репозиторий

```bash
git clone git@github.com:ishapkin/nginx-proxy-letsencrypt.git /srv/proxy
cd /srv/proxy
```

### 2. Настроить переменные окружения

```bash
cp .env.example .env
```

Отредактируйте `.env`:

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `DEFAULT_EMAIL` | Email для уведомлений Let's Encrypt | `admin@example.com` |
| `NGINX_PROXY_CONTAINER` | Имя контейнера прокси | `nginx-proxy` |

### 3. Создать Docker-сеть

```bash
docker network create nginx-proxy
```

### 4. Запустить прокси

```bash
docker-compose up -d
```

## Добавление сервисов

Чтобы проксировать сервис, подключите его к сети `nginx-proxy` и задайте переменные окружения.

Добавьте переменные в `.env` файл сервиса:

```dotenv
VIRTUAL_HOST=example.com
LETSENCRYPT_HOST=example.com
LETSENCRYPT_EMAIL=admin@example.com
```

Пример `docker-compose.yml` для сервиса:

```yaml
services:
  webserver:
    image: nginx:alpine
    container_name: example-webserver
    expose:
      - 80
      - 443
    restart: always
    environment:
      VIRTUAL_HOST: ${VIRTUAL_HOST}
      LETSENCRYPT_HOST: ${LETSENCRYPT_HOST}
      LETSENCRYPT_EMAIL: ${LETSENCRYPT_EMAIL}
    networks:
      - nginx-proxy

networks:
  nginx-proxy:
    external: true
    name: nginx-proxy
```

> Используйте `expose` вместо `ports` -- внешний трафик обрабатывает прокси.

## Редирект с www

Для перенаправления `www.example.com` на `example.com` создайте файл `vhost.d/www.example.com`:

```nginx
if ($request_uri !~ "^/.well-known/acme-challenge") {
    return 301 https://example.com;
}
```

Затем перезапустите:

```bash
docker-compose restart
```

## Базовая аутентификация

Для включения HTTP Basic Auth на домене:

```bash
htpasswd -c htpasswd/example.com username
```

Файл с паролями автоматически монтируется в nginx.

## Структура проекта

```
.
├── docker-compose.yml      # Сервисы прокси и ACME companion
├── .env                    # Переменные окружения (не в git)
├── .env.example            # Пример файла переменных
├── proxy_settings.conf     # Глобальные настройки nginx (client_max_body_size)
├── certs/                  # SSL-сертификаты (генерируются автоматически)
├── acme/                   # Состояние ACME (генерируется автоматически)
├── html/                   # Файлы ACME challenge
├── vhost.d/                # Конфигурации nginx для каждого домена
│   └── default             # Эндпоинт ACME challenge
└── htpasswd/               # Пароли Basic Auth по доменам
```

> Чтобы изменить максимальный размер загрузки, отредактируйте `proxy_settings.conf` и перезапустите прокси.

## Архитектура

```
Интернет (порты 80, 443)
        |
   nginx-proxy (обратный прокси + SSL)
        |
   docker-сеть: nginx-proxy
        |
   контейнеры сервисов (обнаруживаются по VIRTUAL_HOST)
```

Прокси использует Docker-сокет для автоматического обнаружения контейнеров с переменной `VIRTUAL_HOST` и динамически генерирует конфигурацию nginx.
