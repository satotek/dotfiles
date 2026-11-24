{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";

  # Neovim側(lua/plugins/treesitter.lua)と同じ一覧を読み、パーサーの指定を一箇所に保つ。
  treesitterParsers = builtins.fromJSON (
    builtins.readFile ../../../.config/nvim/treesitter-parsers.json
  );
  nvimTreesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    grammars: map (name: grammars.${name}) treesitterParsers
  );

  # tsxのクエリがecma・jsxを継承するように、依存は連鎖する。閉包を集めないとハイライトが欠ける。
  pluginClosure =
    plugins: lib.unique (lib.concatMap (p: [ p ] ++ pluginClosure (p.dependencies or [ ])) plugins);

  # lazy.nvimから1つのプラグインとして読めるよう、本体・parser/・queries/を1ディレクトリにまとめる。
  treesitterRuntime = pkgs.symlinkJoin {
    name = "nvim-treesitter-with-parsers";
    paths = pluginClosure [ nvimTreesitter ];
    # lazy.nvimはdir指定のプラグインのdoc/へ毎回:helptagsを書き込もうとし、読み取り専用の
    # storeでは失敗する。ヘルプは下のtreesitterDocとして、lazyの管理外から読ませる。
    postBuild = "rm -r $out/doc";
  };
  # luamigemoに同梱の辞書(BSD版)は語彙が少ないので、SKK-JISYO.L由来の大きい辞書を渡す。
  # kensaku.vimが既定で使っていたものと同じ、更新されない固定のリリース。
  migemoDict = pkgs.fetchurl {
    url = "https://github.com/oguna/migemo-compact-dict-latest/releases/download/v0.2/migemo-compact-dict";
    sha256 = "06ls5sm87xnxnlmxq55g0573g5qn5knhv4a0rlpj529mnd0c4fps";
  };
  treesitterDoc = pkgs.runCommand "nvim-treesitter-doc" { } ''
    mkdir -p $out
    ln -s ${nvimTreesitter}/doc $out/doc
  '';
in
{
  home.packages = [ pkgs.neovim ];

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/nvim";

  xdg.dataFile."nvim/nix/nvim-treesitter".source = treesitterRuntime;
  xdg.dataFile."nvim/nix/nvim-treesitter-doc".source = treesitterDoc;
  xdg.dataFile."nvim/nix/migemo-compact-dict".source = migemoDict;
}
