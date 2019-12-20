FROM node:6

USER node

COPY --chown=node:node package.json yarn.lock /home/node/app/
WORKDIR /home/node/app
RUN yarn install --modules-folder /home/node/node_modules

COPY --chown=node:node external-scripts.json hubot-scripts.json /home/node/app/
COPY --chown=node:node scripts /home/node/app/scripts

ENV PATH="/home/node/node_modules/.bin:${PATH}"
CMD ["hubot", "--name", "power"]
