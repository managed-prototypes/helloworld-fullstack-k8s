import { defineConfig } from "vite";
// @ts-ignore
import { resolve } from "path";

// --------- User-adjustable

const host = "0.0.0.0"; // "0.0.0.0" = Allow clients from local network

// --------- App-specific

const port = 8080;

// --------- Common

export default defineConfig({
  server: { host, port, strictPort: true },
  build: {
    rollupOptions: {
      input: {
        // @ts-ignore
        main: resolve(__dirname, "index.html"),
        // @ts-ignore
        error: resolve(__dirname, "error.html"),
      },
    },
  },
  preview: { host, port, strictPort: true },
});
