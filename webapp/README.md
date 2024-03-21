## Features

- Assets caching (already set up in the container image)
- Docker build (can be deployed in private environment)
- Application is configured at runtime via environment variables:
  - Application config
  - Whether or not to allow indexing (`robots.txt`)
- Deployment can be done without accessing the source code (Docker image doesn't contain any sources, and customer can parametrize the app via environment variables and deploy wherever they want)

## Prerequisites

- NPM
- Docker

## Local development (without Docker)

- Install dependencies and start dev server

  ```sh
  npm i
  npm start
  ```

- Open http://localhost:8080

## How to add new env variables:

- `public/nocache/config.json` (and set default value for local development)
- `configs/nginx.on-startup.sh` (see the end of file)
- `init.ts` (decode and use new values in your app)
