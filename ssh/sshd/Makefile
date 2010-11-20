# $Id: Makefile,v 1.13 2010/06/01 04:05:37 merdely Exp $
.PATH:                ${SRCDIR}/usr.bin/ssh

PROG=	sshd
BINOWN=	root
BINMODE=555
BINDIR=	/usr/sbin
MAN=	
CFLAGS+=-DHAVE_LOGIN_CAP

# From /usr/src/usr.bin/ssh/sshd/Makefile 1.70
SRCS=	sshd.c auth-rhosts.c auth-passwd.c auth-rsa.c auth-rh-rsa.c \
	sshpty.c sshlogin.c servconf.c serverloop.c \
	auth.c auth1.c auth2.c auth-options.c session.c \
	auth-chall.c auth2-chall.c groupaccess.c \
	auth-bsdauth.c auth2-hostbased.c auth2-kbdint.c \
	auth2-none.c auth2-passwd.c auth2-pubkey.c \
	monitor_mm.c monitor.c monitor_wrap.c \
	kexdhs.c kexgexs.c sftp-server.c sftp-common.c auth2-jpake.c \
	roaming_common.c roaming_serv.c

# From /usr/src/usr.bin/ssh/lib/Makefile 1.61
# remove cleanup.c from line 3
SRCS+=	authfd.c authfile.c bufaux.c bufbn.c buffer.c canohost.c channels.c \
	cipher.c cipher-3des1.c cipher-bf1.c cipher-ctr.c \
	compat.c compress.c crc32.c deattack.c fatal.c \
	hostfile.c log.c match.c nchan.c packet.c readpass.c \
	rsa.c ttymodes.c xmalloc.c atomicio.c \
	key.c dispatch.c kex.c mac.c uidswap.c uuencode.c misc.c \
	ssh-dss.c ssh-rsa.c dh.c kexdh.c kexgex.c \
	kexdhc.c kexgexc.c msg.c progressmeter.c dns.c \
	monitor_fdpass.c umac.c addrmatch.c schnorr.c jpake.c ssh-pkcs11.c

.include <bsd.prog.mk>

DPADD+= ${LIBCRYPTO} ${LIBUTIL} ${LIBZ} ${LIBDES}
LDADD+= -lcrypto -lutil -lz -ldes
