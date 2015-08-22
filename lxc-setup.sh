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

if [[ ! -e $HOME/.ssh/id_rsa ]]; then
  echo -n "Generating SSH keypair..."
  ssh-keygen -q -t rsa -N "" -f $HOME/.ssh/id_rsa
  echo " done!"
fi

if [[ ! -n $CONTAINER_NAME ]]; then
  echo "FATAL: missing container name. (specify with -n <name>)"
  exit 1
fi

HOST_IP=$(curl -s https://api.ipify.org)
if [[ ! -n $HOST_IP ]]; then
  echo "FATAL: could not retrieve host IP."
  exit 1
fi

echo "Creating container $CONTAINER_NAME..."
sudo lxc-create -t download -n $CONTAINER_NAME -- -d ubuntu -r trusty -a amd64
if [[ ! $? -eq 0 ]]; then
  echo "FATAL: could not create container."
  exit 1
fi

CONTAINER_DIR=/var/lib/lxc/$CONTAINER_NAME
CONTAINER_ROOTFS=$CONTAINER_DIR/rootfs
if [[ ! -d $CONTAINER_DIR ]]; then
  echo "FATAL: could not find container folder. Was the container actually created?"
  exit 1
fi

sudo mkdir -p $CONTAINER_ROOTFS/root/.ssh
sudo chmod 700 $CONTAINER_ROOTFS/root/.ssh
cat $HOME/.ssh/id_rsa.pub | sudo tee $CONTAINER_ROOTFS/root/.ssh/authorized_keys 1>/dev/null
sudo chmod 600 $CONTAINER_ROOTFS/root/.ssh/authorized_keys
sudo chown -R 100000:100000 $CONTAINER_ROOTFS/root/.ssh

sudo lxc-start -q -n $CONTAINER_NAME -d
echo "Waiting 10 seconds for container to start..."
sleep 10
echo "Checking container connectivity..."
sudo lxc-attach -q -n $CONTAINER_NAME -- ping -A -c 4 -W 1 8.8.8.8 1>/dev/null
if [[ ! $? -eq 0 ]]; then
  echo "FATAL: container does not seem to be able to access the Internet."
  exit 1
fi

echo "Setting up container connectivity..."
CONTAINER_IP=$(sudo lxc-info -iH -n $CONTAINER_NAME)

#sudo lxc-stop -q -n $CONTAINER_NAME
sudo lxc-attach -q -n $CONTAINER_NAME -- poweroff
sleep 5

sudo sed -i "s/127.0.1.1\s\{0,\}$CONTAINER_NAME/$HOST_IP $CONTAINER_NAME.dedi.laxis.it $CONTAINER_NAME/" $CONTAINER_ROOTFS/etc/hosts
sudo sed -i "s/iface eth0 inet dhcp/iface eth0 inet static\n    address $CONTAINER_IP\n    netmask 255.255.255.0\n    gateway 10.0.3.1\n    dns-nameserver 10.0.3.1\n    dns-search dedi.laxis.it/" $CONTAINER_ROOTFS/etc/network/interfaces

echo "Waiting 10 seconds for container to restart..."
sudo lxc-start -q -n $CONTAINER_NAME -d
sleep 10

echo "Updating APT packages lists..."
sudo lxc-attach -q -n $CONTAINER_NAME -- apt-get -qq update
if [[ ! $? -eq 0 ]]; then
  echo "FATAL: there was a problem updating APT packages lists."
  exit 1
fi

echo "Installing required packages..."
sudo lxc-attach -q -n $CONTAINER_NAME -- apt-get -qq -y install openssh-server nano bash-completion 1>/dev/null
if [[ ! $? -eq 0 ]]; then
  echo "FATAL: errors while installing required packages."
  exit 1
fi

echo "Done!"
echo "You can now access your container with: ssh root@$CONTAINER_IP"
