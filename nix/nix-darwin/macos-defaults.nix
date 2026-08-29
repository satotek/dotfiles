{ ... }:
# macOS のシステム設定を宣言的に管理する。
# 値は実機の `defaults read` から「デフォルトと異なる＝意図して変えた」項目だけを
# 抽出している。新しい項目を足すときも、まず実機で `defaults read <domain>` し、
# デフォルトから変えているものだけを足すこと。
# 型付きオプションに無いものだけ system.defaults.CustomUserPreferences で補う。
{
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false; # Dock に最近使ったアプリを出さない
      tilesize = 46;
      magnification = true;
      largesize = 69; # マウスオーバー時の拡大サイズ
      # AeroSpace がウィンドウを画面外へ退避すると Mission Control が縮小表示になる。
      # アプリ単位でまとめると回避できる。
      expose-group-apps = true;
    };

    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # リスト表示をデフォルトに
      NewWindowTarget = "Home"; # 新規ウィンドウをホームで開く
      ShowHardDrivesOnDesktop = true;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true; # 拡張子を常に表示
      InitialKeyRepeat = 25; # キーリピート開始までの待ち
      KeyRepeat = 2; # キーリピート速度（速い）
    };

    trackpad = {
      Clicking = true; # タップでクリック
    };

    screencapture = {
      target = "clipboard"; # スクショをファイルでなくクリップボードへ
    };
  };
}
