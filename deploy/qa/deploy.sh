#!/usr/bin/env bash
IMAGE=$1
CONTAINER_NAME=favourite-api
docker pull "$IMAGE"
docker rm -f $CONTAINER_NAME 2>/dev/null || true
docker run -d --name $CONTAINER_NAME -p 4000:4000 "$IMAGE"
