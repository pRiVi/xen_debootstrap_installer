#!/bin/bash
. /bin/config.nm.sh
echo $name > /etc/hostname
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
apt-get -y --force-yes install ntpdate ssh nfs-common
mknod /dev/tty1 c 4 1

echo auto lo >/etc/network/interfaces
echo iface lo inet loopback>>/etc/network/interfaces
echo "">>/etc/network/interfaces
echo auto eth0>>/etc/network/interfaces
echo iface eth0 inet manual>>/etc/network/interfaces
echo "">>/etc/network/interfaces
echo auto eth1>>/etc/network/interfaces
echo iface eth1 inet static>>/etc/network/interfaces
echo "   address $prefix.$ip">>/etc/network/interfaces
echo "   netmask 255.255.255.0">>/etc/network/interfaces
echo "   dns-nameservers $dns">>/etc/network/interfaces
echo "   dns-search $searchdns">>/etc/network/interfaces
echo "   gateway $gateway">>/etc/network/interfaces

echo "/dev/null       /       nfs     rw      0       0">/etc/fstab

(crontab -l |egrep -v '^\s*$'|grep -v 'no crontab for' |grep -v /usr/sbin/ntpdate) >/root/new.crontab; echo "41 0 * * * /usr/sbin/ntpdate de.pool.ntp.org" >>/root/new.crontab && crontab /root/new.crontab && rm /root/new.crontab

cat /etc/shadow|egrep -v '^root' >/root/new.shadow; echo 'root:$6$J.SNLZyy$B18vVkn/N8Ucd/eGM9XwQcn21nK1HliU6Y15QMVuM980e7auu7zRAJA.NAiQVc4y7F2XClUA0/YnMPiWpdYg00:15519:0:99999:7:::'>>/root/new.shadow; mv /root/new.shadow /etc/shadow; chown root:shadow /etc/shadow; chmod 640 /etc/shadow

cat /etc/inittab |egrep -v '^1:2345' >/root/new.inittab; echo 1:2345:respawn:/sbin/getty 38400 console>>/root/new.inittab && mv /root/new.inittab /etc/inittab

