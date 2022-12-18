FROM node:18.4.0-bullseye-slim
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm i
COPY . .
EXPOSE 3003
CMD [ "node", "index.js" ]