# dedi-tools
Utility scripts for my dedicated Kimsufi KS-2.

These scripts surely won't work on your configuration out-of-the-box, therefore you are kindly asked
to modify them to suit your needs or even just as a starting point.

## iptables-tee.py
Tool that enables the given iptables rule and puts it into /etc/iptables.rules, a file used to restore
firewall rules on boot on my server.

## lxc-setup.sh
Tool that automates the creation of unprivileged root-created (via sudo) LXC containers and installs
some useful packages.

## trusty64-postinstall.sh
Post-installation script I use for my KS-2 when I install Ubuntu 14.04 64bit (trusty amd64) using my template.
