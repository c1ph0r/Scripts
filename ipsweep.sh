# Copied from [Practical Ethical Hacking - The Complete Course]
# Slightly modified to output results to file and add timestamp to log name.
#!/bin/bash
if [ "$1" == "" ]
then
echo "You forgot an IP address!"
echo "Syntax: ./ipsweep.sh 192.168.1"
else
TIMESTAMP=`date +%Y-%m-%d_%H-%M-%S`
for ip in `seq 1 254`; do
ping -c 1 $1.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" >> scanlog$TIMESTAMP &
done
fi
