# Dev Recipes

- Stop the main `docker-compose`, if running
- Build and run docker images locally

```sh
docker compose -f dc.local-build.yml up --build -Vd
```

- Stop when done

```sh
docker compose -f dc.local-build.yml down -v
```
