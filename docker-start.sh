#!/usr/bin/env bash

docker build -t graphql_bridge . && docker run -it graphql_bridge