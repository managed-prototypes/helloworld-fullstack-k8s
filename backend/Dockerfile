FROM node:20.10-alpine as builder
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy source code and build the app
COPY . .

EXPOSE 8000

# Command to run your application
CMD ["npm", "start"]
