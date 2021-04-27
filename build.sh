#!/bin/bash

docker build . --tag cniweb/cpuminer-multi:1.3.7
docker tag cniweb/cpuminer-multi:1.3.7 ghcr.io/cniweb/cpuminer-multi:1.3.7
docker tag cniweb/cpuminer-multi:1.3.7 ghcr.io/cniweb/cpuminer-multi:latest
docker push ghcr.io/cniweb/cpuminer-multi:1.3.7
docker push ghcr.io/cniweb/cpuminer-multi:latest