#!/bin/sh
exec &>/root/postinstall.log

PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmgBKIauSRY253H4hcrS+0o/rTBKz552KxDC3WiYiBR2y5IFbYa81975ywErVIavBuB/tSLTsXZldf4G9GZ4z5CWCGYo7ccqkwJw+7C4w9Pw2rlQzw6rZKxDL4N1IgeBANL5KT2wfLRmb86ZC2+CUhC6Qnw7HWTTSz5cobKwEloVU2GsUAAdryGmMypJVRP1f1V6pgheCxhFsgvGqZ/6JDXLguSIx3+eslHz3D68etbXf0NFLxj2g7CeL3GA0OPojkdj6h0N1u1FobO1SxQoDNX2K+titAzmec//p5c3H0lMSvjx8MkV3VFIYVRiJU+CNV/Oo57ntNPV7qkb3JR7fKQ== Kimsufi"
TOOLS_DIR="/home/antonio/dedi-tools"

apt-get update
apt-get -y purge bind9 bind9utils && rm -rf /var/cache/bind/
#apt-get -y install linux-image-server && mv /etc/grub.d/06_OVHkernel /etc/grub.d/25_OVHkernel && update-grub
apt-get -y install --install-recommends linux-generic-lts-vivid && mv /etc/grub.d/06_OVHkernel /etc/grub.d/25_OVHkernel && update-grub

rm /etc/localtime && ln -s /usr/share/zoneinfo/CET /etc/localtime
locale-gen; update-locale LANG=en_US.UTF-8

echo "dedi" > /etc/hostname

cat > /etc/resolv.conf << EOT
domain laxis.it
nameserver 213.186.33.99
nameserver 8.8.8.8
nameserver 8.8.4.4
EOT

mv /root/.ssh/authorized_keys2 .ssh/authorized_keys
echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

sed -i 's/Port 22/Port 52020/' /etc/ssh/sshd_config
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin without-password/PermitRootLogin without-password/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/#PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

adduser --disabled-password --gecos "Antonio Ceccato,,," antonio
echo "antonio:changeme" | chpasswd
usermod -aG sudo antonio

mkdir /home/antonio/.ssh
chmod 700 /home/antonio/.ssh
echo "$PUBLIC_KEY" > /home/antonio/.ssh/authorized_keys
chmod 600 /home/antonio/.ssh/authorized_keys
chown -R antonio:antonio /home/antonio/.ssh

apt-get -y install lxc
#echo "antonio veth lxcbr0 10" >> /etc/lxc/lxc-usernet
#mkdir -p /home/antonio/.config/lxc
#cp /etc/lxc/default.conf /home/antonio/.config/lxc/default.conf
#echo "lxc.id_map = u 0 100000 65536" >> /home/antonio/.config/lxc/default.conf
#echo "lxc.id_map = g 0 100000 65536" >> /home/antonio/.config/lxc/default.conf
#chown -R antonio:antonio /home/antonio/.config
usermod --add-subuids 100000-165535 root
usermod --add-subgids 100000-165535 root
echo "lxc.id_map = u 0 100000 65536" >> /etc/lxc/default.conf
echo "lxc.id_map = g 0 100000 65536" >> /etc/lxc/default.conf
echo "lxc.start.auto = 1" >> /etc/lxc/default.conf
echo "lxc.start.delay = 5" >> /etc/lxc/default.conf
chmod +x /var/lib/lxc

apt-get -y install git &&
git clone https://github.com/LaXiS96/dedi-tools.git $TOOLS_DIR &&
chmod +x $TOOLS_DIR/*.sh $TOOLS_DIR/*.py &&
chown -R antonio:antonio $TOOLS_DIR

#ufw allow 52020/tcp && ufw --force enable
cat > /etc/iptables.rules <<EOT
*filter
# Inbound Established
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Inbound Forwardings
-A INPUT -p tcp -m state --state NEW -m multiport --dports 52020 -j ACCEPT
-A INPUT -p icmp -m state --state NEW --icmp-type echo-request -j ACCEPT
# LogDrop
-N LOGDROP
-A LOGDROP -m limit --limit 5/min --limit-burst 10 -j LOG --log-prefix "[iptables] " --log-level 7
-A LOGDROP -j DROP
# Policies
-P INPUT ACCEPT
-A INPUT -j LOGDROP
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
COMMIT
EOT
#iptables-save > /etc/iptables.rules
cat > /etc/network/if-pre-up.d/iptables <<EOT
#!/bin/sh
/sbin/iptables-restore -n < /etc/iptables.rules
EOT
chmod +x /etc/network/if-pre-up.d/iptables
#echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
#echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
#apt-get -y install iptables-persistent

#reboot
