declare module "markdown-it-multimd-table" {
  import type MarkdownIt from "markdown-it";

  interface Options {
    multiline?: boolean;
    rowspan?: boolean;
    headerless?: boolean;
  }

  function multimdTable(md: MarkdownIt, options?: Options): void;
  export default multimdTable;
}
