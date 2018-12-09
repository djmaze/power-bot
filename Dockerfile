FROM node:6

RUN npm install -g yo generator-hubot

# Upgrade yarn to latest stable version
# (b/c of https://github.com/yarnpkg/yarn/commit/b32c4d81080acd87920aa9eac356ebc8e2e8d7cc)
RUN apt-get update && apt-get install -y apt-transport-https \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update && apt-get install -y yarn \
 && rm /var/cache/apt/lists/* -fR \
 && rm /usr/local/bin/yarn

USER node

WORKDIR /home/node/app
COPY --chown=node:node package.json yarn.lock /home/node/app/
RUN yarn install --modules-folder /home/node/node_modules

COPY --chown=node:node scripts external-scripts.json hubot-scripts.json /home/node/app/

ENV PATH="/home/node/node_modules/.bin:${PATH}"
CMD ["hubot", "--name", "power"]
