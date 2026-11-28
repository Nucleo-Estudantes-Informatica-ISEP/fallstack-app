// Reads the closing directives of a pull request body.
//
// A directive is a line that holds only a closing keyword and one or more issue
// numbers, for example `Closes #4`, `- Fixes: #5` or `Resolves #6, #7 and #8`.
// The line may start with up to three spaces and a list marker, and may end with a period.
//
// Everything else is ignored: sentences that mention a keyword ("This does not close #4"),
// quotes, inline code, indented code, fenced code blocks and HTML comments.

const KEYWORD = "(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)";
const REFERENCES = "#\\d+(?:\\s*(?:,|and|&)\\s*#\\d+)*";
const DIRECTIVE = new RegExp(
  `^ {0,3}(?:[-*+]\\s+)?${KEYWORD}:?\\s+(${REFERENCES})\\s*\\.?\\s*$`,
  "i",
);
const OPEN_FENCE = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const CLOSE_FENCE = /^ {0,3}(`{3,}|~{3,})[ \t]*$/;

// Returns the marker when the line opens a fenced code block.
function openingFence(line) {
  const match = line.match(OPEN_FENCE);
  if (!match) return null;
  const [, marker, info] = match;
  // The info string of a backtick fence cannot contain a backtick.
  if (marker[0] === "`" && info.includes("`")) return null;
  return marker;
}

// A closing fence uses the same character, is at least as long as the opening one,
// and may be followed only by spaces or tabs.
function closesFence(line, fence) {
  const marker = line.match(CLOSE_FENCE)?.[1];
  return marker !== undefined && marker[0] === fence[0] && marker.length >= fence.length;
}

function parseClosingIssues(body) {
  const text = (body ?? "").replace(/\r\n?/g, "\n").replace(/<!--[\s\S]*?-->/g, "");
  const numbers = new Set();
  let fence = null;

  for (const line of text.split("\n")) {
    if (fence) {
      if (closesFence(line, fence)) fence = null;
      continue;
    }

    const opened = openingFence(line);
    if (opened) {
      fence = opened;
      continue;
    }

    const directive = line.match(DIRECTIVE);
    if (!directive) continue;
    for (const number of directive[1].match(/\d+/g)) numbers.add(Number(number));
  }

  return [...numbers];
}

module.exports = { parseClosingIssues };
