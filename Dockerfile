#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:stretch

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/fokkersim/netPI-netx-ethernet-lan" \
      org.label-schema.vcs-ref=$VCS_REF

#enable building ARM container on x86 machinery on the web (comment out next line if built on Raspberry)
RUN [ "cross-build-start" ]

#version
ENV IPA_NETPI_CODESYS_NETX 1.0.0

#execute all commands as root
USER root

#labeling
LABEL maintainer="jcj@ipa.fraunhofer.de" \
      version=$IPA_CODESYS_NETX \
      description="CODESYS Control with netX based TCP/IP network interface"

#copy files
COPY "./driver/*" "./firmware/*" /tmp/
COPY "entrypoint.sh" /
#fix windows permissions issue
#RUN chmod +x /entrypoint.sh
	  
#environment variables
ENV USER=pi
ENV PASSWD=raspberry

#do installation
RUN apt-get update  \
    && apt-get install -y openssh-server build-essential ifupdown isc-dhcp-client net-tools psmisc \
#do users
    	&& useradd --create-home --shell /bin/bash pi \
	&& echo 'root:root' | chpasswd \
   	&& echo $USER:$PASSWD | chpasswd \
   	&& adduser $USER sudo \
	&& mkdir /var/run/sshd \
 	&& sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
 	&& sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
	
#install netX driver and netX ethernet supporting firmware
 	&& dpkg -i /tmp/netx-docker-pi-drv-1.1.3-r1.deb \
 	&& dpkg -i /tmp/netx-docker-pi-pns-eth-3.12.0.8.deb \
	
#compile netX network daemon
#    	&& gcc /tmp/cifx0daemon.c -o /opt/cifx/cifx0daemon -I/usr/include/cifx -Iincludes/ -lcifx -pthread \

#compile netX network daemon that creates the cifx0 ethernet interface
    && cp /tmp/cifx0daemon.c /opt/cifx/cifx0daemon.c \
    && gcc /opt/cifx/cifx0daemon.c -o /opt/cifx/cifx0daemon -I/usr/include/cifx -Iincludes/ -lcifx -pthread \

#Codesys
    && touch /usr/bin/modprobe \
    && chmod +x /usr/bin/modprobe \
    && mkdir /etc/modprobe.d \
    && touch /etc/modprobe.d/blacklist.conf \
    && touch /etc/modules \

#clean up
	&& rm -rf /tmp/* \
    	&& apt-get remove build-essential \
    	&& apt-get -yqq autoremove \
    	&& apt-get -y clean \
    	&& rm -rf /var/lib/apt/lists/*

#do ports
EXPOSE 22 1217 4840

#do entrypoint
ENTRYPOINT ["/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#stop processing ARM emulation (comment out next line if built on Raspberry)
RUN [ "cross-build-end" ]
