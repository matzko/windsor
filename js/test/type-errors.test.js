// Compile-time guarantees: each fixture in fixtures/type-errors is a mistake
// the API is designed to reject, and must fail with the expected type error.
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const path = require("node:path");

const FIXTURES = path.join(__dirname, "fixtures", "type-errors");
const ELM = process.env.ELM_BINARY || "elm";

function compile(file) {
  const result = spawnSync(
    ELM,
    ["make", file, "--output=/dev/null", "--report=json"],
    {
      cwd: FIXTURES,
      encoding: "utf8",
    },
  );
  if (result.status === 0) return { ok: true, problems: [] };

  const report = JSON.parse(result.stderr);
  assert.equal(
    report.type,
    "compile-errors",
    `unexpected elm failure:\n${result.stderr}`,
  );
  const problems = report.errors.flatMap((error) =>
    error.problems.map((problem) => ({
      file: path.basename(error.path),
      title: problem.title,
      text: problem.message
        .map((part) => (typeof part === "string" ? part : part.string))
        .join(""),
    })),
  );
  return { ok: false, problems };
}

test("the control fixture compiles", () => {
  const { ok, problems } = compile("WellTyped.elm");
  assert.ok(ok, problems.map((p) => p.text).join("\n\n"));
});

const rejected = [
  {
    file: "HandlerOutsideItsScope.elm",
    why: "a handler needing Authed is routed where only Session exists",
    expect: [
      "List (Route Auth.Authed)",
      "List (Route { user : Maybe Auth.User })",
    ],
  },
  {
    file: "PlugWithoutItsContext.elm",
    why: "a plug needing Session runs where no session was loaded",
    expect: ["List (Route Auth.Session)", "List (Route ())"],
  },
  {
    file: "HandlerWithoutResponse.elm",
    why: "a handler returns its Conn without responding",
    expect: ["(Conn.Conn ctx)", "Sent"],
  },
  {
    file: "MismatchedFormats.elm",
    why: "formats in one view render different data",
    expect: ["View Views.Errors.Data"],
  },
];

for (const { file, why, expect } of rejected) {
  test(`rejects ${file}: ${why}`, () => {
    const { ok, problems } = compile(file);
    assert.ok(!ok, `${file} compiled, but should not have`);
    assert.equal(problems.length, 1, problems.map((p) => p.text).join("\n\n"));

    const [problem] = problems;
    assert.equal(problem.file, file);
    assert.equal(problem.title, "TYPE MISMATCH");
    for (const fragment of expect) {
      assert.ok(
        problem.text.includes(fragment),
        `missing "${fragment}" in:\n${problem.text}`,
      );
    }
  });
}
