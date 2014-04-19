FROM ubuntu
 
RUN apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo

#mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

#ruby
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ruby1.9.3 ruby1.9.1-dev rubygems
RUN apt-get remove -y libruby1.8 ruby1.8 ruby1.8-dev rubygems1.8
RUN gem install rake bundle --no-rdoc --no-ri

#mysql2
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libmysqlclient-dev
RUN gem install mysql2

#huginn
RUN git clone git://github.com/cantino/huginn.git
RUN cd huginn && bundle

#Configuration
ADD . /docker

#Runit Automatically setup all services in the sv directory
RUN for dir in /docker/sv/*; do echo $dir; chmod +x $dir/run $dir/log/run; ln -s $dir /etc/service/; done

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

ENV HOME /root
WORKDIR /root
EXPOSE 22
