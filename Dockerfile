FROM node:6

RUN npm install -g yo generator-hubot

USER node

COPY --chown=node:node package.json /home/node/app/
WORKDIR /home/node/app
RUN npm install

COPY --chown=node:node . /home/node/app

CMD ["bin/hubot"]
