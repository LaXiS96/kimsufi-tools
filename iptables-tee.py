#!/usr/bin/env python
# Usage: echo "-A INPUT -j ACCEPT" | ./iptables-tee.py filter
#        echo "-A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.3.100:80" | ./iptables-tee.py nat
import sys
import os
from subprocess import call

def main():
  if len(sys.argv) < 2:
    print "Missing table specification!"
    exit(1)

  table = sys.argv[1]
  pipe = sys.stdin.read()
  sys.stdin = open("/dev/tty")

  ok = call("sudo iptables -t "+table+" "+pipe, shell=True)
  if ok == 0:
    print "Succesfully applied rule to current configuration."
  else:
    print "Error applying rule to current configuration!"
    exit(1)

  print "Parsing rules file into temp file..."
  with open("/etc/iptables.rules", "r") as rules:
    temp = open("./iptables.temp", "w")
    i = 1
    found_line = 0
    for line in rules:
      line = line.rstrip()
      #print str(i)+":", line
      if found_line == 0 and line.find("*"+table) == 0:
        print "  Found table definition, adding rule..."
        found_line = i
        temp.write(line+"\n"+pipe)
      else:
        temp.write(line+"\n")
      i = i+1
    if found_line == 0:
      print "  Table definition not found, adding table and rule..."
      temp.write("*"+table+"\n")
      temp.write(pipe)
      temp.write("COMMIT\n")
    temp.close()
  print "Confirm: move temp file to /etc/iptables.rules? [Y,n]",
  confirm = raw_input()
  if confirm == "" or confirm == "y" or confirm == "Y":
    print "  Copying..."
    call("sudo cp -f iptables.temp /etc/iptables.rules", shell=True)
  print "Done!"

if __name__ == "__main__":
  main()