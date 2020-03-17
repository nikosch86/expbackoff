#!/bin/bash -eu

expbackoff() {
    # Exponential backoff: retries a command upon failure, scaling up the delay between retries.
    # When max retries are reached, the duration between tries stays at the max value configured
    local TEMP_DIR="/tmp/"
    local CMD_HASH=$(echo -n "$@" | md5sum | awk '{print $1}')
    local CUR_STATUS_DIR="${TEMP_DIR}/${CMD_HASH}"
    local EXPBACKOFF_MAX_RETRIES=8 # Max number of retries
    local EXPBACKOFF_BASE=4 # Base value for backoff calculation
    local EXPBACKOFF_FACTOR=1 # tweak if more backoff is needed
    local EXPBACKOFF_MAX=21600 # Max value for backoff calculation (6 hours)
    local LAST_TRY_TS
    local LAST_TRY
    local RUN_DISTANCE_SECS
    local TS=$(date +"%s")

    if [ ! -d "${CUR_STATUS_DIR}" ]; then
      mkdir -p "${CUR_STATUS_DIR}"
    fi

    if [ -f "${CUR_STATUS_DIR}"/last_try_ts ]; then
      LAST_TRY_TS=$(cat "${CUR_STATUS_DIR}"/last_try_ts)
    fi
    if ! [[ "${LAST_TRY_TS}" =~ ^[0-9]+$ ]]; then
      LAST_TRY_TS=${TS}
    fi

    if [ -f "${CUR_STATUS_DIR}"/last_try ]; then
      LAST_TRY=$(cat "${CUR_STATUS_DIR}"/last_try)
    fi
    if ! [[ "${LAST_TRY}" =~ ^[0-9]+$ ]]; then
      LAST_TRY=0
    fi

    if (( LAST_TRY > EXPBACKOFF_MAX_RETRIES )); then
      RUN_DISTANCE_SECS=${EXPBACKOFF_MAX}
    fi

    # calculate RUN_DISTANCE_SECS
    local RUN_DISTANCE_SECS=$(( (EXPBACKOFF_BASE * EXPBACKOFF_FACTOR) ** LAST_TRY ))
    if (( RUN_DISTANCE_SECS > EXPBACKOFF_MAX )); then
      RUN_DISTANCE_SECS=$EXPBACKOFF_MAX
    fi
    # show_time $RUN_DISTANCE_SECS
    ## echo "${LAST_TRY}/${EXPBACKOFF_MAX_RETRIES} - current distance $RUN_DISTANCE_SECS"

    if (( LAST_TRY > 0 )); then
      # check if last try is at least EXPBACKOFF_MAX seconds ago
      if (( $((TS-LAST_TRY_TS)) < RUN_DISTANCE_SECS )); then
        # echo "not running, time between runs has not exceeded distance $((TS-LAST_TRY_TS)) < ${RUN_DISTANCE_SECS}"
        return 2
      fi
    fi

    local CUR_TRY=$(( LAST_TRY + 1 ))
    if (( CUR_TRY > EXPBACKOFF_MAX_RETRIES )); then
      CUR_TRY=$EXPBACKOFF_MAX_RETRIES
    fi
    # echo "Running ${CUR_TRY}/${EXPBACKOFF_MAX_RETRIES}"

    if ! "$@"; then
      # command failed
      echo "${CUR_TRY}" > "${CUR_STATUS_DIR}"/last_try
      echo "${TS}" > "${CUR_STATUS_DIR}"/last_try_ts
      return 1
    else
      # command successful
      rm -r "${CUR_STATUS_DIR}"
      return 0
    fi
}
