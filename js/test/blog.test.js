// End-to-end tests: build examples/blog, run it with `windsor serve`, and
// exercise it over HTTP. These cover what elm-test can't: anything that runs
// inside a Task, i.e. routing, plugs, scopes, and startup.
const { describe, test, before, after } = require("node:test");
const assert = require("node:assert/strict");
const { spawn, spawnSync } = require("node:child_process");
const net = require("node:net");
const path = require("node:path");

const BLOG = path.resolve(__dirname, "../../examples/blog");
const WINDSOR = path.resolve(__dirname, "../bin/windsor.js");
const SECRET = "test-secret";

before(() => {
  const build = spawnSync(process.execPath, [WINDSOR, "build"], {
    cwd: BLOG,
    encoding: "utf8",
  });
  assert.equal(
    build.status,
    0,
    `windsor build failed:\n${build.stdout}${build.stderr}`,
  );
});

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.on("error", reject);
    server.listen(0, () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });
  });
}

// Only PATH is inherited, so the developer's own environment can't leak in.
function serve(env) {
  const child = spawn(process.execPath, [WINDSOR, "serve"], {
    cwd: BLOG,
    env: { PATH: process.env.PATH, ...env },
    stdio: ["ignore", "pipe", "pipe"],
  });
  child.output = { stdout: "", stderr: "" };
  child.stdout.on("data", (chunk) => (child.output.stdout += chunk));
  child.stderr.on("data", (chunk) => (child.output.stderr += chunk));
  child.exited = new Promise((resolve) =>
    child.on("exit", (code) => resolve(code)),
  );
  return child;
}

describe("a running app", () => {
  let child;
  let port;

  before(async () => {
    port = await freePort();
    child = serve({ PORT: String(port), SESSION_SECRET: SECRET });
    await new Promise((resolve, reject) => {
      child.stdout.on("data", () => {
        if (child.output.stdout.includes("listening")) resolve();
      });
      child.exited.then((code) =>
        reject(new Error(`server exited (${code}):\n${child.output.stderr}`)),
      );
    });
  });

  after(async () => {
    child.kill();
    await child.exited;
  });

  async function get(urlPath, headers = {}) {
    const response = await fetch(`http://localhost:${port}${urlPath}`, {
      headers,
      redirect: "manual",
    });
    return {
      status: response.status,
      headers: response.headers,
      body: await response.text(),
    };
  }

  const loggedIn = { cookie: `session=austin.${SECRET}` };

  describe("views", () => {
    test("renders HTML through a layout", async () => {
      const res = await get("/");
      assert.equal(res.status, 200);
      assert.equal(res.headers.get("content-type"), "text/html; charset=utf-8");
      assert.match(
        res.body,
        /^<!DOCTYPE html><html><head><title>Home · Windsor Blog<\/title>/,
      );
    });

    test("escapes data in HTML", async () => {
      const res = await get("/posts/2");
      assert.match(
        res.body,
        /&lt;script&gt;alert\('escaped'\)&lt;\/script&gt;/,
      );
      assert.doesNotMatch(res.body, /<script>/);
    });

    test("renders JSON for the same handler when asked", async () => {
      const res = await get("/posts/2", { accept: "application/json" });
      assert.equal(res.status, 200);
      assert.equal(res.headers.get("content-type"), "application/json");
      assert.deepEqual(JSON.parse(res.body), {
        id: 2,
        title: "Typed views",
        body: "<script>alert('escaped')</script>",
      });
    });

    test("responds 406 when no format is acceptable", async () => {
      const res = await get("/posts/2", { accept: "image/png" });
      assert.equal(res.status, 406);
    });
  });

  describe("errors", () => {
    test("render as HTML by default", async () => {
      const res = await get("/posts/99");
      assert.equal(res.status, 404);
      assert.equal(res.headers.get("content-type"), "text/html; charset=utf-8");
      assert.match(res.body, /<h1>Not found<\/h1>/);
    });

    test("render as JSON when asked", async () => {
      const res = await get("/nope", { accept: "application/json" });
      assert.equal(res.status, 404);
      assert.deepEqual(JSON.parse(res.body), {
        status: 404,
        error: "Not found",
      });
    });
  });

  describe("plugs and scopes", () => {
    test("a context-preserving plug applies to every route in its scope", async () => {
      for (const urlPath of ["/", "/posts/1", "/login"]) {
        const res = await get(urlPath);
        assert.equal(res.headers.get("x-powered-by"), "windsor", urlPath);
      }
    });

    test("a halting plug stops before the handler", async () => {
      const res = await get("/dashboard");
      assert.equal(res.status, 302);
      assert.equal(res.headers.get("location"), "/login");
      assert.equal(res.body, "");
    });

    test("an invalid session is treated as no session", async () => {
      const res = await get("/dashboard", { cookie: "session=austin.wrong" });
      assert.equal(res.status, 302);
      assert.equal(res.headers.get("location"), "/login");
    });

    test("a handler behind nested scopes receives their context", async () => {
      const res = await get("/dashboard", loggedIn);
      assert.equal(res.status, 200);
      assert.match(res.body, /<h1>Welcome back, austin<\/h1>/);
    });

    test("a handler in an outer scope sees the optional session", async () => {
      assert.equal((await get("/login")).status, 200);
      const res = await get("/login", loggedIn);
      assert.equal(res.status, 302);
      assert.equal(res.headers.get("location"), "/dashboard");
    });
  });
});

describe("startup", () => {
  test("exits when the environment is invalid, without printing values", async () => {
    const child = serve({
      PORT: String(await freePort()),
      DATABASE_PASSWORD: "hunter2",
    });
    const code = await child.exited;
    assert.equal(code, 1);
    assert.match(child.output.stderr, /Invalid environment: .*SESSION_SECRET/);
    assert.doesNotMatch(child.output.stderr + child.output.stdout, /hunter2/);
  });
});
