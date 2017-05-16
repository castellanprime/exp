#!/usr/bin/env bash

REPS=3
DIR=$(dirname "$0")
BRANCH=$(git branch |
         grep "^\*" |
         awk '{print $2}')

if [ "${WHAT}" == "build" ]; then
  # build and push a new image
  IMAGE=vitorenesduarte/lsim
  PULL_IMAGE=Always
  DOCKERFILE=${DIR}/../Dockerfiles/lsim

  BRANCH=${BRANCH} \
    IMAGE=${IMAGE} \
    DOCKERFILE=${DOCKERFILE} "${DIR}"/image.sh

elif [ "${WHAT}" == "run" ]; then
  # use the latest image
  IMAGE=vitorenesduarte/lsim
  PULL_IMAGE=IfNotPresent

else
  # otherwise use image that clones on start
  IMAGE=vitorenesduarte/lsim-dev
  PULL_IMAGE=IfNotPresent
fi

# start redis
"${DIR}"/redis-deploy.sh

# start lsim-dash
#"${DIR}"/lsim-dash-deploy.sh


# lsim configuration
OVERLAY_=(ring)
SIMULATION_=(gset)
NODE_NUMBER_=(3)
NODE_EVENT_NUMBER_=(20)

# ldb configuration
MODE_=(state_based delta_based)
DRIVEN_MODE_=(none)
STATE_SYNC_INTERVAL_=(1000)
REDUNDANT_DGROUPS_=(false true)
DGROUP_BACK_PROPAGATION_=(false true)

# shellcheck disable=SC2034
for REP in $(seq 1 $REPS)
do
  for OVERLAY in "${OVERLAY_[@]}"
  do
    for SIMULATION in "${SIMULATION_[@]}"
    do
      for NODE_NUMBER in "${NODE_NUMBER_[@]}"
      do
        for NODE_EVENT_NUMBER in "${NODE_EVENT_NUMBER_[@]}"
        do
          for LDB_MODE in "${MODE_[@]}"
          do
            for LDB_DRIVEN_MODE in "${DRIVEN_MODE_[@]}"
            do
              for LDB_STATE_SYNC_INTERVAL in "${STATE_SYNC_INTERVAL_[@]}"
              do

                if [ "$LDB_MODE" = state_based ]; then

                  BRANCH=${BRANCH} \
                    IMAGE=${IMAGE} \
                    PULL_IMAGE=${PULL_IMAGE} \
                    LDB_MODE=${LDB_MODE} \
                    LDB_DRIVEN_MODE=${LDB_DRIVEN_MODE} \
                    LDB_STATE_SYNC_INTERVAL=${LDB_STATE_SYNC_INTERVAL} \
                    LDB_REDUNDANT_DGROUPS=undefined \
                    LDB_DGROUP_BACK_PROPAGATION=undefined \
                    OVERLAY=${OVERLAY} \
                    SIMULATION=${SIMULATION} \
                    NODE_NUMBER=${NODE_NUMBER} \
                    NODE_EVENT_NUMBER=${NODE_EVENT_NUMBER} "${DIR}"/lsim-deploy.sh


                elif [ "$LDB_MODE" = delta_based ]; then

                  for LDB_REDUNDANT_DGROUPS in "${REDUNDANT_DGROUPS_[@]}"
                  do
                    for LDB_DGROUP_BACK_PROPAGATION in "${DGROUP_BACK_PROPAGATION_[@]}"
                    do
                      BRANCH=${BRANCH} \
                        IMAGE=${IMAGE} \
                        PULL_IMAGE=${PULL_IMAGE} \
                        LDB_MODE=${LDB_MODE} \
                        LDB_DRIVEN_MODE=${LDB_DRIVEN_MODE} \
                        LDB_STATE_SYNC_INTERVAL=${LDB_STATE_SYNC_INTERVAL} \
                        LDB_REDUNDANT_DGROUPS=${LDB_REDUNDANT_DGROUPS} \
                        LDB_DGROUP_BACK_PROPAGATION=${LDB_DGROUP_BACK_PROPAGATION} \
                        OVERLAY=${OVERLAY} \
                        SIMULATION=${SIMULATION} \
                        NODE_NUMBER=${NODE_NUMBER} \
                        NODE_EVENT_NUMBER=${NODE_EVENT_NUMBER} "${DIR}"/lsim-deploy.sh

                    done
                  done
                fi

              done
            done
          done
        done
      done
    done
  done
done