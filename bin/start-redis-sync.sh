#!/usr/bin/env bash

POD_NAME=$(kubectl describe pod redis |
           grep -E "^Name:" |
           awk '{print $2}')

PORT=6379
DIR=$(dirname $0)

kubectl port-forward ${POD_NAME} ${PORT}:${PORT} & TUNNEL_PID=$!

echo "Port forwarding starting..."
sleep 3

./$DIR/redis-sync.erl

echo "All files downloaded!"

kill ${TUNNEL_PID}

