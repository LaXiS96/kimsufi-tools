#!/bin/sh
while [[ $# > 1 ]]; do
  key="$1"
  case $key in
    -a|--address)
      ADDRESS="$2"
      shift
    ;;
    -hp|--host-port)
      HOST_PORT="$2"
      shift
    ;;
    -gp|--guest-port)
      GUEST_PORT="$2"
      shift
    ;;
    -t|--protocol)
      PROTOCOL="$2"
      shift
    ;;
    *)
    ;;
  esac
  shift
done

if [[ ! -n $ADDRESS ]]; then
  echo "FATAL: missing IP address. (specify with -a <address>)"
  exit 1
fi

if [[ ! -n $HOST_PORT ]]; then
  echo "FATAL: missing host port. (specify with -hp <port>)"
  exit 1
fi

if [[ ! -n $GUEST_PORT ]]; then
  echo "FATAL: missing guest port. (specify with -gp <port>)"
  exit 1
fi

if [[ ! -n $PROTOCOL ]]; then
  echo "FATAL: missing protocol. (specify with -t <protocol>)"
  exit 1
fi

echo "Activating rule..."
sudo iptables -t nat -A PREROUTING -i eth0 -p $PROTOCOL --dport $HOST_PORT -j DNAT --to $ADDRESS:$GUEST_PORT
echo "Done!"
