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
      # ホットコーナー: 左下でデスクトップ。右上は既定のクイックメモを外す（1 = なし）。
      wvous-bl-corner = 4;
      wvous-tr-corner = 1;
    };

    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # リスト表示をデフォルトに
      NewWindowTarget = "Home"; # 新規ウィンドウをホームで開く
      ShowHardDrivesOnDesktop = true;
      _FXSortFoldersFirst = true;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true; # 拡張子を常に表示
      InitialKeyRepeat = 25; # キーリピート開始までの待ち
      KeyRepeat = 2; # キーリピート速度（速い）
      # 長押しでアクセント候補を出さず、キーリピートにする。
      ApplePressAndHoldEnabled = false;
      "com.apple.keyboard.fnState" = true; # F1〜F12 を標準のファンクションキーとして使う
      "com.apple.trackpad.scaling" = 2.0;

      # コードやコマンドを打つときに書き換えられないよう、自動修正をすべて切る。
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    trackpad = {
      Clicking = true; # タップでクリック
      TrackpadThreeFingerDrag = true;
    };

    screencapture = {
      target = "clipboard"; # スクショをファイルでなくクリップボードへ
    };

    menuExtraClock = {
      ShowSeconds = true;
      ShowDate = 1; # 常に日付を出す
    };

    # AeroSpace の推奨設定。ディスプレイごとに Spaces を分けると、ディスプレイを
    # またぐウィンドウの扱いが不安定になる。
    spaces.spans-displays = true;

    WindowManager = {
      # 壁紙のクリックで全ウィンドウを退避させない。AeroSpace の操作中に誤爆する。
      EnableStandardClickToShowDesktop = false;
      # ⌥ を押しながらのドラッグで macOS のタイル配置を出さない（AeroSpace と競合）。
      EnableTilingOptionAccelerator = false;
    };

    CustomUserPreferences = {
      # 画面端へのドラッグによるタイル配置も止める。型付きオプションに無い。
      "com.apple.WindowManager" = {
        EnableTilingByEdge = false;
        EnableTopTilingByEdge = false;
      };
      # ネットワークドライブと USB メディアに .DS_Store を作らない。
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
    };
  };
}
