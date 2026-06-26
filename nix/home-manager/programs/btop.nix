{ pkgs, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      # ターミナル(wezterm/ghostty)に合わせて Catppuccin Mocha。
      # テーマ実体は下の xdg.configFile で取得する。
      color_theme = "catppuccin_mocha";
      theme_background = true;
      truecolor = true;
      rounded_corners = true;
      vim_keys = true;

      # 反応を良くする(VM でも負荷増はほぼ無い)。
      update_ms = 1000;

      # どのプロセスが重いかを見たいので CPU 降順・フラット表示。
      proc_sorting = "cpu lazy";
      proc_tree = false;

      # メモリ box 内にディスク使用量を表示(物理のみ)。
      show_disks = true;
      only_physical = true;

      # 温度/消費電力は btop デフォルト(有効)のまま。Mac/物理機では表示され、
      # センサーの無い VM では自動的に何も出ないだけ(全環境共通の base 向け)。
    };
  };

  # btop 同梱テーマに catppuccin は含まれないため、固定コミットから取得して配置する。
  xdg.configFile."btop/themes/catppuccin_mocha.theme".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/btop/f437574b600f1c6d932627050b15ff5153b58fa3/themes/catppuccin_mocha.theme";
    hash = "sha256-THRpq5vaKCwf9gaso3ycC4TNDLZtBB5Ofh/tOXkfRkQ=";
  };
}
