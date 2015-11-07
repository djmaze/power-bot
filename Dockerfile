FROM node:4.2

RUN npm install -g yo generator-hubot

RUN groupadd -g 1000 app && useradd -u 1000 -g app -m -s /bin/bash app && mkdir /usr/src/app && chown app /usr/src/app

USER app
WORKDIR /usr/src/app
