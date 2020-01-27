#!/bin/bash

[ $(id -u) -ne 0 ] && echo "Please run as root" && exit 1

busybox='busybox-1.31.1'

use() {
cat << EOF

Use: ./mkinitramfs.sh -b /mnt -i /dev/sda7 OR -i /home/root.img -d /boot/iniramfs

	-b / OR /chroot			Use the base dir for copy modules
	-i /root/root.img		The device file system OR root image file
	-d /boot/initramfs		Dest of initramfs

EOF
exit 1
}

path_ini=$(pwd)

mkinitramfs() {
	local base=$2
	local device=$4
	local dest=$6

	kernel_version=$(uname -r)
	temp="$(mktemp -d)"
	initramfs="$temp/initramfs"
	mkdir $initramfs

	#############
	## BUSYBOX ##
	#############

	if [ ! -x $busybox/initramfs/bin/busybox ]; then
		wget https://busybox.net/downloads/${busybox}.tar.bz2
		tar xpfj ${busybox}.tar.bz2
		cp -rfp .config ${busybox}/.config
		cd ${busybox} && make && make install
	fi

	[ ! -d $busybox/initramfs ] && echo "WHITHOUT BUSYBOX, COMPILE IT" && exit 0

	cp -rfp $busybox/initramfs/* $initramfs

	##########
	## INIT ##
	##########
	cp -rfp ./init $initramfs/init
	mkdir $initramfs/etc
	touch $initramfs/etc/modules

	if [ -f $device ]; then
		sd=$(df -P $device | awk 'END{print $1}')
		uuid=$(blkid $sd -sUUID -ovalue)
		image=$(basename $device)
		sed -i "s*^##A0*/bin/mkdir /mnt*" $initramfs/init
		sed -i "s*^##A1*/bin/mount UUID=${uuid} /mnt*" $initramfs/init
		sed -i "s*^##A2*/sbin/losetup -o ${offset} /dev/loop0 /mnt/${image}*" $initramfs/init
		sed -i "s*^##A3*/bin/mount /dev/loop0 /newroot*" $initramfs/init
	fi

	#############
	## MODULES ##
	#############
	mkdir -p $initramfs/lib/modules/${kernel_version}

	# DETECT THE MODULES FOR YOUR PC
	devices=$(find /sys/devices -name modalias -type f -print0 | xargs -0 sort -u)
	for i in $devices; do
		modules=$(modprobe -D $i 2>/dev/null|awk '{print $2}')
		for mod in $modules; do
			cp --parents $mod $initramfs
		done
	done

	# ATTENTION
	fstype=$(blkid -o value -s TYPE $device)

	for i in $fstype; do
        dependencies=$(cat /lib/modules/${kernel_version}/modules.dep|grep "/$i\."|sed s'/://')
        for d in $dependencies; do
            cp --parents /lib/modules/${kernel_version}/$d $initramfs
        done
    done

	# Make the /etc/modules of INITRAMFS for load ALL
	toload=$(find $initramfs/lib/modules -name '*.ko*')
	for i in $toload; do
	    tofile=$(echo ${i/*\//}|cut -d '.' -f 1)
	   echo $tofile >> $initramfs/etc/modules
	done

	# Make the depmod for modprobe
	touch $initramfs/lib/modules/${kernel_version}/modules.order
	touch $initramfs/lib/modules/${kernel_version}/modules.builtin
	depmod -b $initramfs -a $kernel_version

	###########
	## CLOSE ##
	###########
	cd $initramfs
	find > $path_ini/log.txt
	find . -print0 | cpio --null -ov --format=newc | gzip -9 > $dest
	rm -rf $temp
}

#################################
## ARGUMENTS PASSED FOR SCRIPT ##
#################################
while getopts ":b:i:dh" option; do
	case "${option}" in
		b) base=${OPTARG};;
		i) device=${OPTARG};;
		d) dest=${OPTARG};;
		h) use;;
	esac
done

######################
## VERIFY ARGUMENTS ##
######################
if ([ ! -d $base ] && [ -f $device ]); then
	base="/mnt"
	echo "Mount the image $device, in base $base"
	modprobe loop
	sleep 1
	offset=$(parted -m ${device} unit B print | grep ext4 | cut -d ':' -f2 | sed 's/.$//')
	losetup -o ${offset} /dev/loop0 $device
	mount /dev/loop0 $base
else
	base="/"
fi

[ -z $device ] && device=$(mount|grep ' / '|cut -d ' ' -f1)
[ -z $dest ] && dest="/boot/initramfs-lts"

###################
## DO THE THINGS ##
###################
mkinitramfs -b "$base" -o "$device" -d "$dest"

##################
## UNMOUNT LOOP ##
##################
[ ! -z "$(findmnt -M /mnt)" ] && umount $base && losetup -d /dev/loop0

[ -f $dest ] && echo "Initramfs created: $(du -sh $dest)"
