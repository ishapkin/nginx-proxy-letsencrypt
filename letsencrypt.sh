docker stop nginx-proxy-letsencrypt &&
docker rm nginx-proxy-letsencrypt &&
docker run --detach \
    --name nginx-proxy-letsencrypt \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion
