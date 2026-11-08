const http = require("node:http");
const ConcurrentTask = require("@andrewmacmurray/elm-concurrent-task");

const MAX_BODY_BYTES = 1024 * 1024;
const REQUEST_TIMEOUT_MS = 30_000;
const PORT_NAMES = [
  "windsorRequest",
  "windsorRespond",
  "windsorTaskSend",
  "windsorTaskReceive",
];

function start({ Elm, port = 3000, env = {}, tasks = {}, log = console }) {
  const app = Elm.Main.init({ flags: { env } });

  for (const name of PORT_NAMES) {
    if (!app.ports?.[name]) {
      throw new Error(
        `Elm app is missing port "${name}". Is main defined with Windsor.application?`,
      );
    }
  }

  const pending = new Map();
  let nextId = 1;

  function finish(id, status, headers, body) {
    const entry = pending.get(id);
    if (!entry) return; // already timed out
    pending.delete(id);
    clearTimeout(entry.timer);

    const { res, method, url, startedAt } = entry;
    res.statusCode = status;
    for (const [name, value] of headers) res.appendHeader(name, value);
    res.end(body);
    log.info(`${method} ${url} -> ${status} (${Date.now() - startedAt}ms)`);
  }

  app.ports.windsorRespond.subscribe((message) => {
    switch (message?.type) {
      case "response":
        finish(message.id, message.status, message.headers, message.body);
        break;
      case "fatal":
        log.error(message.error);
        process.exit(1);
    }
  });

  const server = http.createServer((req, res) => {
    const chunks = [];
    let size = 0;

    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        res.writeHead(413).end("Payload Too Large");
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });

    req.on("end", () => {
      if (res.writableEnded) return;

      const id = nextId++;
      const timer = setTimeout(
        () => finish(id, 504, [], "Gateway Timeout"),
        REQUEST_TIMEOUT_MS,
      );
      pending.set(id, {
        res,
        timer,
        method: req.method,
        url: req.url,
        startedAt: Date.now(),
      });

      app.ports.windsorRequest.send({
        id,
        request: {
          method: req.method,
          url: req.url,
          headers: req.headers,
          body: Buffer.concat(chunks).toString("utf8"),
        },
      });
    });
  });

  server.listen(port, () =>
    log.info(`Windsor listening on http://localhost:${port}`),
  );

  async function shutdown() {
    server.close();
    process.exit(0);
  }
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);

  return { server, app, shutdown };
}

module.exports = { start };
