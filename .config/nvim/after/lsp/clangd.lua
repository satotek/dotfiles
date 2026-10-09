-- background-index と clang-tidy は既定オフ。補完と診断をプロジェクト全体に広げる。
return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
  },
}
