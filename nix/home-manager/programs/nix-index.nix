{ inputs, ... }:
{
  # nix-index のデータベースを自前で生成すると数十分かかるため、毎週ビルドされた
  # ものを使う。zsh の command-not-found は提供パッケージを案内するだけで、
  # NIX_AUTO_RUN を設定しない限り勝手に実行しない（非端末時は案内もしない）。
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  programs.nix-index-database.comma.enable = true;
}
