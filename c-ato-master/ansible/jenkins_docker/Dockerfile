FROM jenkins/jenkins:lts

USER root
RUN mkdir /var/log/jenkins
RUN mkdir /var/cache/jenkins
RUN chown -R jenkins:jenkins /var/cache/jenkins
RUN chown -R jenkins:jenkins /var/log/jenkins
RUN apt-get update \
      && apt-get install -y sudo libltdl7 \
      && rm -rf /var/lib/apt/lists/*
RUN adduser jenkins sudo
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers
RUN sudo apt update -y
RUN apt install python3-pip curl gnupg apt-transport-https -y
RUN pip3 install requests jinja2 argparse urllib3 openpyxl
RUN curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list'
RUN apt-get update
RUN apt-get install -y powershell

USER jenkins
ENV JAVA_OPTS="-Xmx8192m"
ENV JENKINS_OPTS="--handlerCountMax=300 --logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war --httpPort=-1 --httpsPort=8443 --httpsKeyStore=/var/jenkins_home/keys/keystore.jks --httpsKeyStorePassword=changeit"
