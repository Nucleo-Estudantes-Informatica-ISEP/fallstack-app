// Run with: node --test .github/scripts/
const assert = require("node:assert/strict");
const { test } = require("node:test");
const { parseClosingIssues } = require("./closing-issues.js");

const parse = (body) => parseClosingIssues(body);

test("reads a directive on its own line", () => {
  assert.deepEqual(parse("Closes #4"), [4]);
  assert.deepEqual(parse("closed #4"), [4]);
  assert.deepEqual(parse("FIXES: #4"), [4]);
  assert.deepEqual(parse("Resolves #4."), [4]);
});

test("reads list items and several issues", () => {
  assert.deepEqual(parse("- Fixes #5\n* Resolves: #6\n+ Closes #7"), [5, 6, 7]);
  assert.deepEqual(parse("Closes #7, #8 and #9"), [7, 8, 9]);
  assert.deepEqual(parse("Closes #1 & #2"), [1, 2]);
});

test("reads a directive in a full pull request body", () => {
  const body = [
    "## Related issue",
    "",
    "Closes #4",
    "",
    "Refs #16 (the rest comes later)",
    "",
    "## Description",
    "",
    "Adds CI.",
  ].join("\n");
  assert.deepEqual(parse(body), [4]);
});

test("reads directives in a body with Windows line endings", () => {
  assert.deepEqual(parse("Closes #4\r\n\r\nFixes #5\r\n"), [4, 5]);
});

test("ignores prose that mentions a keyword", () => {
  assert.deepEqual(parse("This does not close #11."), []);
  assert.deepEqual(parse("It should not fix #11 yet"), []);
  assert.deepEqual(parse("Closes #11 only partly"), []);
  assert.deepEqual(parse("see also: closes #11"), []);
});

test("ignores Refs and bare mentions", () => {
  assert.deepEqual(parse("Refs #5"), []);
  assert.deepEqual(parse("Related to #5"), []);
  assert.deepEqual(parse("#5"), []);
});

test("ignores the empty pull request template placeholder", () => {
  assert.deepEqual(parse("## Related issue\n\nCloses #\n"), []);
});

test("ignores quoted examples", () => {
  assert.deepEqual(parse("> Closes #12"), []);
  assert.deepEqual(parse("> quoted\n> - Fixes #12"), []);
});

test("ignores inline code and indented code", () => {
  assert.deepEqual(parse("`Closes #14`"), []);
  assert.deepEqual(parse("Write `Closes #14` to close it."), []);
  assert.deepEqual(parse("    Closes #15"), []);
  assert.deepEqual(parse("\tCloses #15"), []);
});

test("ignores fenced code blocks", () => {
  assert.deepEqual(parse("```\nCloses #13\n```"), []);
  assert.deepEqual(parse("```md\nCloses #13\n```\nCloses #14"), [14]);
  assert.deepEqual(parse("~~~\nCloses #13\n~~~"), []);
  assert.deepEqual(parse("````\n```\nCloses #13\n```\n````"), []);
  assert.deepEqual(parse("```\nCloses #13"), []);
});

test("ignores HTML comments", () => {
  assert.deepEqual(parse("<!-- Closes #16 -->"), []);
  assert.deepEqual(parse("<!--\nCloses #16\n-->\nCloses #17"), [17]);
});

test("ignores keywords inside emphasis and other formatting", () => {
  assert.deepEqual(parse("**Closes #4**"), []);
});

test("returns each issue once", () => {
  assert.deepEqual(parse("Closes #4\nFixes #4\nCloses #4, #4"), [4]);
});

test("handles an empty or missing body", () => {
  assert.deepEqual(parse(""), []);
  assert.deepEqual(parse(null), []);
  assert.deepEqual(parse(undefined), []);
});
