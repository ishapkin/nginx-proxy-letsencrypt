# Docker + nginx-proxy + letsencrypt

Проект (далее прокси) предназначен для быстрого развертывания nginx с автоматиески обновляемыми сертифкатами от Letsencrypt.
Не стоит ставить это на уже готовый вебсервер, так порты будут конлфиктовать
Подходит для разворачивания микросервисной архитектуры на новой машине или рядом с апачом

### Требования:
Любая ось на которой работает docker + docker-compose

### Клонируем прокси в /srv/ или любую другую удоную папку
```bash
    git clone git@github.com:ishapkin/nginx-proxy-letsencrypt.git /srv/proxy
```

### Создаем сеть nginx-proxy
```bash
    docker create network nginx-proxy
```

### Собираем контейнер с прокси 
```bash
    docker-compose up -d --build
```

### Собираем контейнер с letsencrypt
```bash
    ./letsencrypt_build.sh
```

### Пример использования:
```yaml
version: '3'

services:
  webserver:
    image: nginx:alpine
    container_name: example-webserver
     # пробрасываем порты 80 и 443 для работы прокси
    expose:
      - 80
      - 443
    restart: always
    environment:
      # Хост для прокси
      VIRTUAL_HOST: example.com
      # Хост для letsencrypt
      LETSENCRYPT_HOST: example.com
      # Хост для letsencrypt email админа
      LETSENCRYPT_EMAIL: email@example.com

# Подключаем сеть с прокси
networks:
  default:
    external:
      name: nginx-proxy

```

# TODO:
### HTTP basic auth
### Redirect from www 