#!/bin/bash

if [[ "$2" == "" ]]; then
   echo "1. parameter: hostname, 2. parameter: last octet of ip 3. paramter(optional): Debian version 4. parameter(optional): Architecture";
   exit;
fi;

export name=$1
export ip=$2
export rls=$3
export arch=$4

if [[ "$rls" == "" ]]; then echo RLS is undefined: $rls; export rls=wheezy; fi
if [[ "$arch" == "" ]]; then echo ARCH is undefined: $arch; export arch=amd64; fi

export basepath="/mnt/xen-current"
. /bin/config.nm.sh
unset LANG
if [[ -e $basepath/$name ]]; then
   echo System already existing \($basepath/$name\);
   exit;
fi;
echo Installing debian $rls $arch
debootstrap --arch $arch $rls $basepath/$name/ http://ftp.de.debian.org/debian/ # squeeze wuerde auch gehen
#cp -pvr /lib/modules/2.6.18.8-xen/ $basepath/$name/lib/modules/ # Nur wenn man einen Modularenkernel hat (im MOment nicht)
mkdir $basepath/$name/root/.ssh/
cp /root/.ssh/authorized_keys $basepath/$name/root/.ssh/
cp /bin/config.nm.sh $basepath/$name/bin/config.nm.sh
cp /bin/nm2.sh $basepath/$name/bin/nm2.sh
chroot $basepath/$name/ /bin/bash /bin/nm2.sh

echo memory=1024>$basepath/$name.cfg
echo kernel=\"$xenkernel\">>$basepath/$name.cfg
if [[ "$initrd" != "" ]]; then
   echo ramdisk=\"$initrd\">>$basepath/$name.cfg;
fi;
echo extra=\"ip=192.0.0.$ip:::255.255.255.0::eth0: nfsroot=192.0.0.1:$basepath/$name/,v3,tcp root=/dev/nfs xencons=tty\">>$basepath/$name.cfg
echo vif=[\"bridge=br255\",\"bridge=$br\"]>>$basepath/$name.cfg
echo name=\"$name\">>$basepath/$name.cfg
echo vcpus=4 >>$basepath/$name.cfg
echo cpus=\"0-7\">>$basepath/$name.cfg
echo on_crash=\"preserve\">>$basepath/$name.cfg
echo vnclisten=\"127.0.0.1\">>$basepath/$name.cfg

svn update $exportsfile
cat /etc/exports |grep -v 192.0.0.$ip >/root/new.exports;
echo "$basepath/$name/ 192.0.0.$ip/255.255.255.255(rw,no_root_squash,async,no_subtree_check)">>/root/new.exports;
cat /root/new.exports|perl -e 'while (<>) { chomp; if (m,^(\/.*?)(\d+\.[\d\.]+),) { $curline = $_; $ip = $2; if ($1 =~ m,^\/mnt\/xen-current\/,){ $line->{$ip} = $curline; } else { print $curline."\n"; } } }; print join("\n", map { $line->{$_} } sort { $a cmp $b } keys %$line)."\n";' >/etc/exports
svn diff $exportsfile
read -p "STRG+C fuer abbruch..."
svn commit -m "$name/$ip" $exportsfile
/etc/init.d/nfs-kernel-server reload

