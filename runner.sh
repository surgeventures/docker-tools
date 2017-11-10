#!/bin/bash

while [[ $# -gt 0 ]]; do
  case $1 in
    await)
      host="$2"
      port="$3"
      echo "Waiting for $2:$3..."
      i="0"
      while ! nc $2 $3; do
        i=$((i+1))
        sleep 1
        if [ $i -ge 5 ]; then
          echo "Timeouted waiting for $2:$3"
          exit 1
        fi
      done
      shift
      shift
      shift
      ;;

    run)
      argc="$2"
      shift
      shift
      it="0"
      cmd=()
      while [ $it -lt $argc ]; do
        it=$((it+1))
        cmd+=("$1")
        shift
      done
      echo "Executing ${cmd[@]}..."
      eval ${cmd[@]}
      ;;

    *)
      echo "Unknown command: $1"
      exit 1
      shift
      ;;

  esac
done
