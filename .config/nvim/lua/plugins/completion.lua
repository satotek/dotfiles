-- Show the LSP completion item kind (Function, Class, Variable, ...) as text
-- in addition to LazyVim's kind icon.
return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
          },
        },
      },
    },
  },
}
