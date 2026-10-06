{
  config,
  inputs,
  self,
  username,
  ...
}:
let
  # nix-homebrew は自分の flake.lock のタグを版として埋めるので、brew-src を
  # 差し替えたときはこちらの flake.lock から取り直す。
  brewVersion =
    (builtins.fromJSON (builtins.readFile (self + "/flake.lock"))).nodes.brew-src.original.ref;
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
    };
  };

  homebrew = {
    enable = true;
    # 宣言外のパッケージが残っていれば消さずに switch を止める。
    # 棚卸しを終えてから "uninstall" に上げる。
    onActivation.cleanup = "check";
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
      "karabiner-elements"
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
      "yubico-authenticator"

      # ドキュメント・ノート
      "google-drive"
      "mactex"
      "notion"
      "obsidian"

      # メディア・クリエイティブ
      "affinity"
      "foobar2000"
      "musicbrainz-picard"
      "obs"

      # ユーティリティ
      "appcleaner" # Homebrew 以外で入れたアプリを残りのファイルごと消す
      "daisydisk"
    ];
  };
}
