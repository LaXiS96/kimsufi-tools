#!/bin/sh
while [[ $# > 1 ]]; do
  key="$1"
  case $key in
    -n|--name)
      CONTAINER_NAME="$2"
      shift
    ;;
    *)
    ;;
  esac
  shift
done

if [[ ! -n $CONTAINER_NAME ]]; then
  echo "FATAL: missing container name. (specify with -n <name>)"
  exit 1
fi

sudo lxc-stop -n $CONTAINER_NAME
sudo lxc-destroy -n $CONTAINER_NAME
