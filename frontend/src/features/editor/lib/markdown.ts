import MarkdownIt from "markdown-it";
import markdownItMultimdTable from "markdown-it-multimd-table";
import DOMPurify from "dompurify";

const md = new MarkdownIt({
  html: false,
  linkify: true,
  typographer: true,
}).use(markdownItMultimdTable, {
  multiline: true,
  rowspan: true,
  headerless: true,
});

const defaultFence =
  md.renderer.rules.fence ??
  ((tokens, idx, options, _env, self) => self.renderToken(tokens, idx, options));

md.renderer.rules.fence = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  const language = (token.info || "").trim().split(/\s+/)[0];

  if (language === "mermaid") {
    return `<pre class="mermaid">${escapeHtml(token.content)}</pre>\n`;
  }

  return defaultFence(tokens, idx, options, env, self);
};

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function renderMarkdownToHtml(markdown: string): string {
  const raw = md.render(markdown);
  return DOMPurify.sanitize(raw, {
    ADD_TAGS: ["pre"],
    ADD_ATTR: ["class", "data-language"],
  });
}
