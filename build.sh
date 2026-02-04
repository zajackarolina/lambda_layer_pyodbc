#!/bin/bash
set -e

IMAGE_NAME=lambda-pyodbc-312
CONTAINER_NAME=lambda-pyodbc-extract

docker build -t $IMAGE_NAME .
docker create --name $CONTAINER_NAME $IMAGE_NAME
docker cp $CONTAINER_NAME:/layer/layer.zip ./layer.zip
docker rm $CONTAINER_NAME

echo "✅ Gotowe: layer.zip"
