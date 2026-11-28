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
const FENCE = /^ {0,3}(`{3,}|~{3,})/;

function parseClosingIssues(body) {
  const text = (body ?? "").replace(/\r\n?/g, "\n").replace(/<!--[\s\S]*?-->/g, "");
  const numbers = new Set();
  let fence = null;

  for (const line of text.split("\n")) {
    const marker = line.match(FENCE)?.[1];

    if (fence) {
      if (marker && marker[0] === fence[0] && marker.length >= fence.length) fence = null;
      continue;
    }
    if (marker) {
      fence = marker;
      continue;
    }

    const directive = line.match(DIRECTIVE);
    if (!directive) continue;
    for (const number of directive[1].match(/\d+/g)) numbers.add(Number(number));
  }

  return [...numbers];
}

module.exports = { parseClosingIssues };
