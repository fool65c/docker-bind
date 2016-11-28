from ubuntu:16.04

# update box
RUN apt-get update

# add the bind use
RUN useradd -ms /bin/bash bind

# install bind9
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-host

# setup add bind config files
COPY config/named.conf /etc/bind/named.conf
COPY config/named.conf.local /etc/bind/named.conf.local

# add hosts
COPY config/house.mager.hosts /var/lib/bind/house.mager.hosts
COPY config/null.zone.file /var/lib/bind/null.zone.file

# install curl
RUN apt-get install -y curl

# install update script
COPY support/update_adblock.sh /usr/sbin/update_adblock.sh
RUN chmod a+x /usr/sbin/update_adblock.sh
RUN /usr/sbin/update_adblock.sh

 CMD ["/usr/sbin/named", "-u", "bind", "-fg"]