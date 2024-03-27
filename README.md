# fullstack-k8s

## Purpose

- Set up an app in a k8s cluster
  - Load balancer
  - `cert-manager` (for HTTPS)
  - Fullstack app
    - webapp, 2 instances
    - backend, 2 instances
    - Each app on its own subdomain, DNS records, CORS
  - Local dev setup via `docker compose`

## Development

- [Design](docs/design.md)
- [Prerequisites](docs/prerequisites.md)
- [Dev Recipes](docs/dev-recipes.md)

## Processes

- [Deployment via GitHub Actions](docs/deployment-github-actions.md)
- [Deployment via CLI](docs/deployment-cli.md)
- [Updating Dependencies](docs/updating-dependencies.md)
