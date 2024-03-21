"use strict";

const Hapi = require("@hapi/hapi");

const init = async () => {
  const server = Hapi.server({
    port: 8000,
    host: "0.0.0.0",
  });

  server.route({
    method: "POST",
    path: "/hello",
    handler: (request, h) => {
      const responseString =
        typeof request.payload === "string"
          ? request.payload
          : JSON.stringify(request.payload);
      return "Hello, " + responseString;
    },
  });

  await server.start();
  console.log("Server running on %s", server.info.uri);
};

process.on("unhandledRejection", (err) => {
  console.log(err);
  process.exit(1);
});

init();
