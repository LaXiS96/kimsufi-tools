#!/usr/bin/env python
# Usage: echo "-A INPUT -j ACCEPT" | ./iptables-tee.py filter
#        echo "-A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.3.100:80" | ./iptables-tee.py nat
import sys
import os
from subprocess import call

def help():
  print ""
  print "Usage: echo \"<rule-specification>\" | ./iptables-tee.py <table>"
  print "   or: ./iptables-tee.py <table>, then write your rule-spec and press Enter"
  print "       followed by Ctrl-D"
  print " WARN: Please avoid using commands other than Append (-A) or Insert (-I)."
  print "       Other commands will surely mess up your persistent rules."
  print "       WATCH OUT! New rules are always inserted on top of the existing"
  print "       persistent rules."
  print "Ex. 1: echo \"-A INPUT -j ACCEPT\" | ./iptables-tee.py filter"
  print "Ex. 2: echo \"-A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.3.100:80\" | ./iptables-tee.py nat"

def main():
  if len(sys.argv) < 2:
    print "Missing table specification!"
    help()
    exit(1)

  table = sys.argv[1]
  pipe = sys.stdin.read().rstrip()
  sys.stdin = open("/dev/tty")

  ok = call("sudo iptables -t "+table+" "+pipe, shell=True)
  if ok == 0:
    print "Succesfully applied rule to current configuration."
  else:
    print "Error applying rule to current configuration! Please check your rule-spec."
    exit(1)

  print "Parsing rules file into temp file..."
  with open("/etc/iptables.rules", "r") as rules:
    temp = open("./iptables.temp", "w")
    i = 1
    found_line = 0
    for line in rules:
      line = line.rstrip()
      if found_line == 0 and line.find("*"+table) == 0:
        print "  Found table definition, adding rule..."
        found_line = i
        temp.write(line+"\n"+pipe+"\n")
      else:
        temp.write(line+"\n")
      i = i+1
    if found_line == 0:
      print "  Table definition not found, adding table and rule..."
      temp.write("*"+table+"\n")
      temp.write(pipe+"\n")
      temp.write("COMMIT\n")
    temp.close()
  print "Confirm: move temp file to /etc/iptables.rules? [Y,n]",
  confirm = raw_input()
  if confirm == "" or confirm == "y" or confirm == "Y":
    print "  Copying...",
    call("sudo cp -f iptables.temp /etc/iptables.rules", shell=True)
  print "Done!"

if __name__ == "__main__":
  main()
