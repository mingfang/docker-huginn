FROM ubuntu:14.04
 
RUN apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#ruby
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ruby1.9.3 ruby1.9.1-dev
RUN gem install rake bundle --no-rdoc --no-ri

#mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server mysql-client libmysqlclient-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential

RUN gem install mysql2

#huginn
RUN git clone git://github.com/cantino/huginn.git
RUN cd huginn && bundle

#Add runit services
ADD sv /etc/service 

#Configuration

#env file
RUN cd /huginn && \
    cp .env.example .env && \
    sed -i 's|REPLACE_ME_NOW!|49fcd18f9d1e0834c1c6c66b70937b64|' .env

#Seed mysql
RUN mysqld_safe & mysqladmin --wait=5 ping && \
    cd /huginn && \
    bundle exec rake db:create && \
    bundle exec rake db:migrate && \
    bundle exec rake db:seed && \
    mysqladmin shutdown

