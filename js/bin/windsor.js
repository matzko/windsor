#!/usr/bin/env node
const { spawn, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { start } = require("../src");

const cwd = process.cwd();
const ELM = process.env.ELM_BINARY || "elm";
const OUTPUT = path.join("build", "elm.js");

const commands = {
  build: () => process.exit(build({ optimize: true }) ? 0 : 1),
  serve,
  migrate: () =>
    migrate({ cwd, database: loadConfig(cwd).database }).catch((error) => {
      console.error(error.message);
      process.exit(1);
    }),
};

const command = commands[process.argv[2]];
if (!command) {
  console.log(`Usage: windsor <command>

Commands:
  build     Compile src/Main.elm
  serve     Run the compiled app in build/elm.js`);
  process.exit(process.argv[2] ? 1 : 0);
}
command();

function build({ optimize }) {
  const args = [
    "make",
    "src/Main.elm",
    `--output=${OUTPUT}`,
    ...(optimize ? ["--optimize"] : []),
  ];
  return spawnSync(ELM, args, { cwd, stdio: "inherit" }).status === 0;
}

function serve() {
  const compiled = path.join(cwd, OUTPUT);
  if (!fs.existsSync(compiled)) {
    console.error(`${OUTPUT} not found. Run \`windsor build\` first.`);
    process.exit(1);
  }
  const envFile = path.join(cwd, ".env");
  if (fs.existsSync(envFile)) process.loadEnvFile(envFile);
  const { Elm } = require(compiled);
  start({ Elm, port: Number(process.env.PORT) || 3000, env: process.env });
}
