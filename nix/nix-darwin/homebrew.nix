{ ... }:
{
  homebrew = {
    enable = true;
    brews = [
      "herdr" # agent multiplexer (tmux-like TUI for AI coding agents)
    ];
    casks = [
      "1password" # SSH エージェント / コミット署名 / 認証情報の元
      "1password-cli" # op コマンド（署名検証やシークレット取得に使用）
      "karabiner-elements"
      "wezterm@nightly"
    ];
  };
}
