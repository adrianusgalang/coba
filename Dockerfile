FROM mhart/alpine-node

ADD https://releases.hashicorp.com/envconsul/0.6.2/envconsul_0.6.2_linux_amd64.tgz /tmp/

ADD . /app
WORKDIR /app
RUN npm install && tar -xf /tmp/envconsul* -C /bin && rm /tmp/*

EXPOSE 8080

CMD ["bin/hubot", "--adapter", "slack"]
