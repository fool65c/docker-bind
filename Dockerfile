from ubuntu:16.04

# update box
RUN apt-get update

# add the bind use
RUN useradd -ms /bin/bash bind

# install bind9
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-host

# setup add named.conf.local
COPY source/named.conf.local /etc/bind/named.conf.local

# add house.mager.hosts
COPY source/house.mager.hosts /var/lib/bind/house.mager.hosts

 CMD ["/usr/sbin/named", "-u", "bind", "-fg"]