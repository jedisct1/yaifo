# $Id: Makefile,v 1.34 2010/11/08 02:18:38 merdely Exp $

.if !defined(SRCDIR)
SRCDIR=/usr/src
.endif
P!=pwd
TOP=${P}/..

RAMDISK=	RAMDISK_YAIFO
XNAME=		yaifo
MOUNT_POINT=	/mnt
IMAGE=		mr.fs
CBIN?=		instbin
CRUNCHCONF?=	${CBIN}.conf
LISTS?=		${.CURDIR}/list
LISTS+=		${.CURDIR}/${MACHINE}/list
UTILS?=		${SRCDIR}/distrib/miniroot
MTREE=		${UTILS}/mtree.conf
FS?=		${XNAME}.fs
VND?=		vnd0
VND_DEV=	/dev/${VND}a
VND_RDEV=	/dev/r${VND}a
VND_CRDEV=	/dev/r${VND}c
PID!=		echo $$$$
REALIMAGE!=	echo /var/tmp/image.${PID}

STRIP=		strip
OBJCOPY=	objcopy -Sg -R .comment 
LABEL=		${.CURDIR}/${MACHINE}/label
RDLABEL=	${.CURDIR}/${MACHINE}/rdlabel
STAND=		${SRCDIR}/sys/arch/${MACHINE}/stand

IMAGESIZE=	8192
RDSIZE=		8192
NEWFSOPTS=	-m 0 -o space -i 4096
LABELOPTS?=	-R ${VND} ${LABEL}
RDLABELOPTS?=	-R ${VND} ${RDLABEL}

# architecture specific variables
.if ${MACHINE} == "alpha"
BOOT=		/usr/mdec/boot
BOOTXX=		/usr/mdec/bootxx
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/boot
INSTALLB=	${INSTALLBOOT} -v ${BOOTOUT} ${BOOTXX} ${VND_CRDEV}
.elif ${MACHINE} == "amd64"
BOOT=		/usr/mdec/boot
BOOTXX=		/usr/mdec/biosboot
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/boot
INSTALLB=	${INSTALLBOOT} -v ${BOOTOUT} ${BOOTXX} ${VND_CRDEV}
.elif ${MACHINE} == "i386"
BOOT=		/usr/mdec/boot
BOOTXX=		/usr/mdec/biosboot
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/boot
INSTALLB=	${INSTALLBOOT} -v ${BOOTOUT} ${BOOTXX} ${VND_CRDEV}
.elif ${MACHINE} == "landisk"
BOOT=		/usr/mdec/boot
BOOTXX=		/usr/mdec/biosboot
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/boot
INSTALLB=	true
.elif ${MACHINE} == "macppc"
BOOT=		/usr/mdec/ofwboot
BOOTXX=		/usr/mdec/boot.mac
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/ofwboot
INSTALLB=	${INSTALLBOOT} -v ${BOOTXX} ${VND_CRDEV}
.elif ${MACHINE} == "sgi"
BOOT=		/usr/mdec/boot
BOOTXX=		/usr/mdec/sgivol
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/ofwboot
INSTALLB=	${INSTALLBOOT} -v ${BOOTXX} ${VND_CRDEV}
CRUNCH_M=	-M
RDSIZE=		9728
.elif ${MACHINE} == "sparc"
BOOT=		/var/tmp/usr/mdec/boot
BOOTXX=		/var/tmp/usr/mdec/bootxx
INSTALLBOOT=	/var/tmp/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/boot
INSTALLB=	${INSTALLBOOT} -v ${BOOTOUT} ${BOOTXX} ${VND_CRDEV}
IMAGESIZE=	4096
RDSIZE=		6176
.elif ${MACHINE} == "sparc64"
BOOT=		/usr/mdec/ofwboot
BOOTXX=		/usr/mdec/bootblk
INSTALLBOOT=	/usr/mdec/installboot
BOOTOUT=	${MOUNT_POINT}/ofwboot
INSTALLB=	${INSTALLBOOT} -v ${BOOTXX} ${VND_CRDEV}
NEWFSOPTS=	-m 0 -o space -i 8192
IMAGESIZE=	8192
RDSIZE=		8192
.endif

keys:
	@echo "===>  Copying keys from ~/.ssh & /etc/ssh"
	[ -s ~/.ssh/authorized_keys ] || exit 1
	cp ~/.ssh/authorized_keys ${.CURDIR} || exit 1
	sudo cp /etc/ssh/ssh_host*_key* ${.CURDIR} || exit 1

${.CURDIR}/authorized_keys:
.if !exists(${.CURDIR}/authorized_keys)
	@echo "===>  Error: ${.CURDIR}/authorized_keys does not exist."
	@echo "===>  Create or copy an authorized_keys file."
	@echo "===>  Refer to ssh-keygen(1) if necessary."
	@exit 1
.endif

all: ${.CURDIR}/authorized_keys arch ${FS}
.if ${MACHINE} == "macppc" || ${MACHINE} == "sgi" || ${MACHINE} == "landisk"
	@cp ${.OBJDIR}/bsd.gz ../${XNAME}.rd
	@echo "successfully created yaifo.rd."
.else
	@cp ${.OBJDIR}/${XNAME}.fs ..
	@cp ${.OBJDIR}/bsd.gz ../${XNAME}.rd
	@echo "successfully created yaifo.rd and yaifo.fs."
.endif

REALLY?=	NO
KERNEL?=	/bsd
install:
.if ${REALLY} != "YES" 
	@echo "You aren't REALLY sure you want to install YAIFO over your kernel."
	@echo "If you were, you would run: REALLY=YES make install"
	@exit 1
.else
	@if [ -f /etc/boot.conf ]; then \
		KERNEL=`awk '/^set image/ { printf "/%s",$$3 }' /etc/boot.conf`; \
	fi; \
	echo "Installing yaifo.rd ${KERNEL}..."; \
	${SUDO} rm -f /obsd && \
	${SUDO} ln ${KERNEL} /obsd && \
	${SUDO} cp ${TOP}/yaifo.rd /nbsd && \
	${SUDO} mv /nbsd ${KERNEL} && \
	sync && sync
.endif

${FS}:	bsd.gz
.if ${MACHINE} != "macppc" && ${MACHINE} != "sgi" && ${MACHINE} != "landisk"
	dd if=/dev/zero of=${REALIMAGE} count=${IMAGESIZE}
	${SUDO} vnconfig -v -c ${VND} ${REALIMAGE}
	${SUDO} disklabel ${LABELOPTS}
	${SUDO} newfs ${NEWFSOPTS} ${VND_RDEV}
	${SUDO} mount ${VND_DEV} ${MOUNT_POINT}
	${SUDO} cp ${BOOT} ${BOOTOUT}
	${SUDO} cp bsd.gz ${MOUNT_POINT}/bsd 
	${SUDO} mkdir -p ${MOUNT_POINT}/etc
	${SUDO} cp ${.CURDIR}/boot.conf ${MOUNT_POINT}/etc/
	${SUDO} ${INSTALLB} 
	@echo ""
	@df -i ${MOUNT_POINT}
	@echo ""
	${SUDO} umount ${MOUNT_POINT}
	${SUDO} vnconfig -u ${VND}
	dd if=${REALIMAGE} of=${FS} count=${IMAGESIZE}
	rm ${REALIMAGE}
.else
	touch ${FS}
.endif

bsd.gz: bsd.rd
	${OBJCOPY} bsd.rd bsd.strip
	${STRIP} bsd.strip
	gzip -c9f bsd.strip > bsd.gz

bsd.rd:	${IMAGE} bsd rdsetroot
	cp bsd bsd.rd
	${.OBJDIR}/rdsetroot bsd.rd < ${IMAGE}

bsd:
	mkdir -p ${.OBJDIR}/kernel
	config -b ${.OBJDIR}/kernel -s ${SRCDIR}/sys ${TOP}/${MACHINE}/${RAMDISK}
	cd ${.OBJDIR}/kernel && \
		make clean && make depend && COPTS=-Os make
	cp ${.OBJDIR}/kernel/bsd bsd

${IMAGE}: ${CBIN} rd_setup do_files rd_teardown

rd_setup: ${CBIN}
	dd if=/dev/zero of=${REALIMAGE} bs=512 count=${RDSIZE}
	${SUDO} vnconfig -v -c ${VND} ${REALIMAGE}
	${SUDO} disklabel ${RDLABELOPTS}
	${SUDO} newfs ${NEWFSOPTS} ${VND_RDEV}
	${SUDO} fsck ${VND_RDEV}
	${SUDO} mount ${VND_DEV} ${MOUNT_POINT}

rd_teardown:
	@df -i ${MOUNT_POINT}
	-${SUDO} umount ${MOUNT_POINT}
	-${SUDO} vnconfig -u ${VND}
	cp ${REALIMAGE} ${IMAGE}
	rm ${REALIMAGE}

rdsetroot:	${SRCDIR}/distrib/common/elfrdsetroot.c
	${HOSTCC} -DDEBUG -o rdsetroot ${SRCDIR}/distrib/common/elfrdsetroot.c

unconfig:
	-${SUDO} umount -f ${MOUNT_POINT}
	-${SUDO} vnconfig -u ${VND}

${CBIN}.mk ${CBIN}.cache ${CBIN}.c: ${CRUNCHCONF}
.if ${MACHINE} == "macppc" || ${MACHINE} == "landisk"
	${SUDO} crunchgen -E -D ${SRCDIR} -L /usr/lib \
	${.ALLSRC}
.else
	${SUDO} crunchgen ${CRUNCH_M} -E -D ${SRCDIR} -L /usr/lib \
	-c ${CBIN}.c -e ${CBIN} -m ${CBIN}.mk ${CRUNCHCONF}
.endif

${CBIN}: ${CBIN}.mk ${CBIN}.cache ${CBIN}.c
	env SRCDIR=${SRCDIR} make -f ${CBIN}.mk all
	${STRIP} ${CBIN}

${CRUNCHCONF}: ${LISTS} distrib_ssh distrib_obj
	awk -f ${UTILS}/makeconf.awk CBIN=${CBIN} ${LISTS} > ${CRUNCHCONF}

distrib_ssh: ${SRCDIR}/distrib/special/ssh

${SRCDIR}/distrib/special/ssh:
	${SUDO} cp -Rp ${.CURDIR}/ssh ${SRCDIR}/distrib/special/
	${SUDO} chgrp -R wsrc ${SRCDIR}/distrib/special/ssh
	${SUDO} chmod -R g+w ${SRCDIR}/distrib/special/ssh

distrib_obj:
	cd ${SRCDIR}/distrib && make obj
	cd ${SRCDIR}/distrib/special/ssh/sshd && make obj

do_files:
.if !exists(${.CURDIR}/ssh_host_rsa_key)
	ssh-keygen -q -t rsa -f ${.CURDIR}/ssh_host_rsa_key -N ''
.endif
.if !exists(${.CURDIR}/ssh_host_dsa_key)
	ssh-keygen -q -t dsa -f ${.CURDIR}/ssh_host_dsa_key -N ''
.endif
.if !exists(${.CURDIR}/ssh_host_key)
	ssh-keygen -q -t rsa1 -f ${.CURDIR}/ssh_host_key -N ''
.endif
	grep -Ev "^(#|$$)" ${.CURDIR}/sshd_config > ${.CURDIR}/sshd_config_small
	${SUDO} mtree -def ${MTREE} -p ${MOUNT_POINT}/ -u
	${SUDO} env TOPDIR=${TOP} CURDIR=${.CURDIR} OBJDIR=${.OBJDIR} SRCDIR=${SRCDIR} \
		ARCH=${MACHINE} TARGDIR=${MOUNT_POINT} UTILS=${UTILS} \
		sh ${UTILS}/runlist.sh ${LISTS}
	${SUDO} rm ${MOUNT_POINT}/${CBIN}

.if ${MACHINE} == "sparc"
arch:
	cd ${STAND} && env RELOC=0x480000 make && \
	env NOMAN= DESTDIR=/var/tmp make install 
	@/var/tmp/usr/mdec/binstall net /tmp
	cp /tmp/boot.sparc.openbsd ../${XNAME}.net
	@echo "for netinstall with yaifo.rd you need yaifo.net as bootloader"
.else
arch:
	
.endif

clean:
	/bin/rm -f core ${IMAGE} ${CBIN} ${CBIN}.mk ${CBIN}*.cache \
		${TOP}/${XNAME}.fs ${TOP}/${XNAME}.rd ${TOP}/sshd_config_small \
		*.o *.lo *.c

cleanall cleandir: arch_clean
	cd ${SRCDIR}/distrib/special && make clean
	${SUDO} /bin/rm -f core ${IMAGE} ${CBIN} ${CBIN}.mk ${CBIN}*.cache \
		*.o *.lo *.c bsd bsd.rd bsd.gz bsd.strip floppy*.fs \
		rdsetroot ${CRUNCHCONF} ${FS} \
		 ${TOP}/${XNAME}.fs ${TOP}/${XNAME}.rd
	${SUDO} /bin/rm -rf ${TOP}/obj || /bin/rm -rf ${TOP}/obj
	${SUDO} /bin/rm -rf ${SRCDIR}/distrib/special/ssh
.for p in sbin/mount_cd9660 bin/df sbin/mount sbin/mount_ext2fs bin/sync \
		sbin/restore bin/stty bin/ln sbin/disklabel bin/pax sbin/ping \
		bin/cat bin/ls sbin/rtsol sbin/ping6 sbin/fdisk sbin/mount_nfs \
		sbin/mount_msdos sbin/umount sbin/mount_udf sbin/fsck \
		sbin/mknod sys/arch/${MACHINE}/stand/installboot sbin/route \
		sbin/reboot sbin/mount_ffs bin/ed bin/cp bin/chmod \
		sbin/fsck_ffs usr.sbin/apmd bin/rm bin/mt bin/mkdir \
		usr.bin/sed bin/ksh bin/sleep bin/mv bin/expr usr.sbin/apm \
		bin/hostname
	if [ -d ${SRCDIR}/$p ]; then cd ${SRCDIR}/$p && make clean; fi
.endfor

.if ${MACHINE} == "sparc"
arch_clean:
	cd ${STAND} && make clean
	rm ${TOP}/${XNAME}.net
.else
arch_clean:

.endif

YAIFO_FILES =	${.CURDIR}/dot.profile ${SRCDIR}/distrib/miniroot/dot.profile \
		${.CURDIR}/install.sh ${SRCDIR}/distrib/miniroot/install.sh \
		${.CURDIR}/install.sub ${SRCDIR}/distrib/miniroot/install.sub \
		${.CURDIR}/list ${SRCDIR}/distrib/miniroot/list \
		${.CURDIR}/sshd_config ${SRCDIR}/usr.bin/ssh/sshd_config \
		${.CURDIR}/alpha/RAMDISK_YAIFO ${SRCDIR}/sys/arch/alpha/conf/RAMDISKBIG \
		${.CURDIR}/amd64/RAMDISK_YAIFO ${SRCDIR}/sys/arch/amd64/conf/RAMDISK_CD \
		${.CURDIR}/i386/RAMDISK_YAIFO ${SRCDIR}/sys/arch/i386/conf/RAMDISK_CD \
		${.CURDIR}/landisk/RAMDISK_YAIFO ${SRCDIR}/sys/arch/landisk/conf/RAMDISK \
		${.CURDIR}/macppc/RAMDISK_YAIFO ${SRCDIR}/sys/arch/macppc/conf/RAMDISK \
		${.CURDIR}/sgi/RAMDISK_YAIFO ${SRCDIR}/sys/arch/sgi/conf/RAMDISK-IP32 \
		${.CURDIR}/sparc/RAMDISK_YAIFO ${SRCDIR}/sys/arch/sparc/conf/RAMDISK \
		${.CURDIR}/sparc64/RAMDISK_YAIFO ${SRCDIR}/sys/arch/sparc64/conf/RAMDISK

check-updates:
.for yfile ofile in ${YAIFO_FILES}
	@yver=`awk '/#[	 ]\\$$OpenBSD: / { print $$4 }' ${yfile}`; \
	over=`awk '/#[	 ]\\$$OpenBSD: / { print $$4 }' ${ofile}`; \
	if [ $$yver != $$over ]; then \
		printf "%-25s %s\\n" "${yfile}:" "$$yver -> $$over"; \
	fi
.endfor
	@yver=`awk '/# From \/usr\/src\/usr.bin\/ssh\/sshd\/Makefile / \
		{ print $$4 }' ${.CURDIR}/ssh/sshd/Makefile`; \
	over=`awk '/#	\\$$OpenBSD: / { print $$4 }' \
		${SRCDIR}/usr.bin/ssh/sshd/Makefile`; \
	if [ $$yver != $$over ]; then \
		printf "%-25s %s (%s)\\n" "${.CURDIR}/ssh/sshd/Makefile" \
		"$$yver -> $$over" "${SRCDIR}/usr.bin/ssh/sshd/Makefile"; \
	fi
	@yver=`awk '/# From \/usr\/src\/usr.bin\/ssh\/lib\/Makefile / \
		{ print $$4 }' ${.CURDIR}/ssh/sshd/Makefile`; \
	over=`awk '/#	\\$$OpenBSD: / { print $$4 }' \
		${SRCDIR}/usr.bin/ssh/lib/Makefile`; \
	if [ $$yver != $$over ]; then \
		printf "%-25s %s (%s)\\n" "${.CURDIR}/ssh/sshd/Makefile" \
		"$$yver -> $$over" "${SRCDIR}/usr.bin/ssh/lib/Makefile"; \
	fi

do-updates:
.for yfile ofile in ${YAIFO_FILES}
	@yver=`awk '/#[	 ]\\$$OpenBSD: / { print $$4 }' ${yfile}`; \
	over=`awk '/#[	 ]\\$$OpenBSD: / { print $$4 }' ${ofile}`; \
	echo yver=$$yver; echo over=$$over; \
	if [ $$yver != $$over ]; then \
		dfile=`mktemp` && \
		(cd `dirname ${ofile}` && \
		cvs diff -r $$yver `basename ${ofile}` > $$dfile || true); \
		patch ${yfile} $$dfile; \
	fi
.endfor
	@yver=`awk '/# From \/usr\/src\/usr.bin\/ssh\/sshd\/Makefile / \
		{ print $$4 }' ${.CURDIR}/ssh/sshd/Makefile`; \
	over=`awk '/#	\\$$OpenBSD: / { print $$4 }' \
		${SRCDIR}/usr.bin/ssh/sshd/Makefile`; \
	if [ $$yver != $$over ]; then \
		echo -n "Update ${.CURDIR}/ssh/sshd/Makefile from "; \
		echo "${SRCDIR}/usr.bin/ssh/sshd/Makefile v$$over"; \
	fi
	@yver=`awk '/# From \/usr\/src\/usr.bin\/ssh\/lib\/Makefile / \
		{ print $$4 }' ${.CURDIR}/ssh/sshd/Makefile`; \
	over=`awk '/#	\\$$OpenBSD: / { print $$4 }' \
		${SRCDIR}/usr.bin/ssh/lib/Makefile`; \
	if [ $$yver != $$over ]; then \
		echo -n "Update ${.CURDIR}/ssh/sshd/Makefile from "; \
		echo "${SRCDIR}/usr.bin/ssh/lib/Makefile v$$over"; \
	fi

get-files:
	${SUDO} cp /etc/ssh/ssh_host* .
	${SUDO} chown `id -u`:`id -g` ssh_host*
	cp ${HOME}/.ssh/authorized_keys .

.include <bsd.obj.mk>
.include <bsd.subdir.mk>
