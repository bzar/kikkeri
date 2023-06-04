FROM node:19 AS build

COPY . .
ENV NODE_ENV development
RUN npm install
RUN node_modules/gulp/bin/gulp.js build

FROM node:19
WORKDIR /srv/app
COPY package.json .
ENV NODE_ENV production
RUN npm install
COPY --from=build build build
ENTRYPOINT ["npm", "run", "start"]