#!/usr/bin/env bash

DIR=$(dirname "$0")

IMAGE=vitorenesduarte/exp-copy:nbs

IMAGE=${IMAGE} ${DIR}/bench_retwis.sh
IMAGE=${IMAGE} ${DIR}/bench_micro.sh
IMAGE=${IMAGE} ${DIR}/bench_metadata.sh