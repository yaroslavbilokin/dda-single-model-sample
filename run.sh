#!/bin/bash

docker run --rm \
  --gpus all  \
  --name sdlatest \
  -p 8000:8000 \
  sd:latest
