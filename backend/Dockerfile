FROM node:20-alpine

WORKDIR /app

# Placeholder Dockerfile
# Substituir quando a stack do backend for definida

COPY package*.json ./
RUN npm install --production || true

COPY . .

EXPOSE 3000

CMD ["node", "src/index.js"]
