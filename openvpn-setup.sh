#!/bin/sh
if [[ $EUID -ne 0 ]]; then
  echo "FATAL: this script must be run as root."
  exit 1
fi

apt-get update
apt-get install openvpn easy-rsa
adduser --system --no-create-home --group openvpn

rm -rf /etc/openvpn/easy-rsa
mkdir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
cp /usr/share/easy-rsa/* .

sed -i 's/export KEY_COUNTRY=.*/export KEY_COUNTRY="IT"/' vars
sed -i 's/export KEY_PROVINCE=.*/export KEY_PROVINCE="Treviso"/' vars
sed -i 's/export KEY_CITY=.*/export KEY_CITY="Cavaso del Tomba"/' vars
sed -i 's/export KEY_ORG=.*/export KEY_ORG="LaXiS"/' vars
sed -i 's/export KEY_EMAIL=.*/export KEY_EMAIL="antonio.ceccato@hotmail.it"/' vars
sed -i 's/export KEY_OU=.*/export KEY_OU="LaXiS"/' vars

source ./vars
./clean-all
chmod 700 keys
./build-ca
./build-dh
./build-key-server vpn.laxis.it
