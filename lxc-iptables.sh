#!/bin/sh
while [[ $# > 1 ]]; do
  key="$1"
  case $key in
    -a|--address)
      ADDRESS="$2"
      shift
    ;;
    -p|--port)
      PORT="$2"
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

if [[ ! -n $PORT ]]; then
  echo "FATAL: missing port. (specify with -p <port>)"
  exit 1
fi

if [[ ! -n $PROTOCOL ]]; then
  echo "FATAL: missing protocol. (specify with -t <protocol>)"
  exit 1
fi

echo "Activating rule..."
sudo iptables -t nat -A PREROUTING -i eth0 -p $PROTOCOL --dport $PORT -j DNAT --to $ADDRESS:$PORT
echo "Done!"
