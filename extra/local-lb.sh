#!/bin/sh

docker kill vagrant-kubernetes-haproxy 2> /dev/null
docker rm vagrant-kubernetes-haproxy 2> /dev/null

DIR="$( cd "$( dirname $0 )" &> /dev/null && pwd )"

docker run -d \
    -p 80:80 \
    -p 443:443 \
    -p 9000:9000 \
    -v "$DIR/configuration/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro" \
    --restart always \
    --name vagrant-kubernetes-haproxy \
    haproxy:2.3