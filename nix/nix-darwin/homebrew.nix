{
  config,
  inputs,
  pkgs,
  self,
  username,
  ...
}:
let
  # nix-homebrew は自分の flake.lock のタグを版として埋めるので、brew-src を
  # 差し替えたときはこちらの flake.lock から取り直す。
  brewVersion =
    (builtins.fromJSON (builtins.readFile (self + "/flake.lock"))).nodes.brew-src.original.ref;

  # herdr-app は公式 cask を配布していない（配布物は署名済み .app のみ）。
  # dotfiles 内に置いた cask を Nix 管理の tap として渡し、名前で参照できるようにする。
  herdrTap = pkgs.runCommandLocal "homebrew-herdr" { } ''
    mkdir -p $out/Casks
    cp -L ${./homebrew-herdr/Casks/herdr-app.rb} $out/Casks/herdr-app.rb
  '';

  # Meltype も公式 cask が無い。mac 版フォークの tap を追うのをやめ、上流の
  # リリースをそのまま指す cask を自前 tap として持つ（版の更新は手で追う）。
  meltypeTap = pkgs.runCommandLocal "homebrew-meltype" { } ''
    mkdir -p $out/Casks
    cp -L ${./homebrew-meltype/Casks/meltype-for-mac.rb} $out/Casks/meltype-for-mac.rb
  '';
in
{
  imports = [ ./homebrew-video.nix ];

  nix-homebrew = {
    enable = true;
    package = inputs.brew-src // {
      name = "brew-${brewVersion}";
      version = brewVersion;
    };
    user = username;
    # 既存の /opt/homebrew を初回 activation で nix-homebrew 管理に引き継ぐ。
    autoMigrate = true;
    # tap は flake input だけにして、`brew tap` で宣言外の tap が増えないようにする。
    mutableTaps = false;
    taps = {
      "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko-tap;
      "nosuke/homebrew-herdr" = herdrTap;
      "nosuke/homebrew-meltype" = meltypeTap;
    };
  };

  homebrew = {
    enable = true;
    # アプリの設定・データを残しつつ、インストール済みの一覧を宣言に揃える。
    onActivation.cleanup = "uninstall";
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [
      # コンテナ（Apple 純正の container）
      "container"
      "container-compose"

      # ビルド
      "cocoapods" # Flutter の iOS / macOS ビルドが pod install を呼ぶ
      "gcc"

      # その他
      "iperf3"
      "typst"
    ];

    casks = [
      # AI
      "antigravity"
      "chatgpt"
      "claude"
      "grok-bot"
      "handy" # 音声入力（文字起こし）
      "nosuke/herdr/herdr-app" # Herdr の GUI（herdr-core を操作するクライアント）
      "t3-code" # エージェントの GUI。gem-ai のサーバーへは T3 Connect でつなぐ

      # エディタ・IDE
      "android-studio"
      "cursor"
      "visual-studio-code@insiders"
      "zed"

      # 開発ツール
      "beekeeper-studio" # SQL クライアント
      "caido" # Web の通信を中継して検査する（Burp Suite の代替）
      "flutter"
      "orbstack" # Docker Desktop の代替
      "utm"
      "vysor" # Android 端末の画面ミラーリング
      "wireshark-app"

      # ウィンドウ・入力
      "dockdoor" # Dock のウィンドウプレビューとウィンドウ単位の切り替え
      "jordanbaird-ice" # メニューバーのアイコンを整理・非表示にする
      "karabiner-elements"
      "nosuke/meltype/meltype-for-mac" # 英数キーなしで日英を切り替える IME（上流ビルド）
      "nikitabobko/tap/aerospace" # i3 風タイリングウィンドウマネージャ
      "raycast"

      # ブラウザ
      "firefox"
      "google-chrome"

      # セキュリティ・ネットワーク
      "1password" # SSH エージェント / コミット署名 / 認証情報の元
      "1password-cli" # op コマンド（署名検証やシークレット取得に使用）
      "adguard"
      "surfshark"
      "tailscale-app"
      "yubico-authenticator"

      # ドキュメント・ノート
      "google-drive"
      "mactex"
      "notion"
      "obsidian"

      # メディア・クリエイティブ
      "affinity"
      "drawio" # 図解・ダイアグラム作成（draw.io Desktop）
      "foobar2000"
      "musicbrainz-picard"
      "obs"

      # フォント
      # nixpkgs に単体パッケージが無いため cask で入れる。fonts.nix 側と同じ
      # ファミリーを二重に入れないこと。
      "font-line-seed-jp" # UI 用の日本語フォント

      # ユーティリティ
      "appcleaner" # Homebrew 以外で入れたアプリを残りのファイルごと消す
      "daisydisk"
    ];
  };
}
