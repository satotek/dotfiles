cask "meltype-for-mac" do
  version "1.4.0"
  sha256 "2ab38a85acd1b5f7098a0850fb52fc2c9c3e4bd3089ccaaf185ce419d7ec0e35"

  url "https://github.com/yksr-melt/Meltype/releases/download/v#{version}/Meltype-#{version}-mac.zip"
  name "Meltype"
  desc "Japanese input method with English-aware conversion"
  homepage "https://github.com/yksr-melt/Meltype"

  livecheck do
    url :url
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        release["tag_name"]&.[](regex, 1)
      end
    end
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # 上流の macOS ビルドは Apple Silicon のみ。
  depends_on arch: :arm64
  depends_on macos: :ventura

  input_method "Meltype-mac/Meltype.app"

  postflight_steps do
    # 上流の配布物は ad-hoc 署名で公証を受けていない。quarantine 属性が残ると
    # Gatekeeper が IME を黙って止める（起動は imklaunchagent が行うため、
    # 「開発元を確認できません」も表示されず、入力メニューに出ないだけになる）。
    # run の args は base で解決されず、サンドボックス内の $HOME も偽のホームを
    # 指すので、/Users/{{user}} で本物のホームを指す。
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "/Users/{{user}}/Library/Input Methods/Meltype.app"],
        must_succeed:   false,
        writable_paths: ["Library/Input Methods/Meltype.app"],
        writable_base:  :home
    # 入れ替え中に動いている IME と辞書の管理画面を止める（無ければ無視）。
    terminate_process "Meltype"
    terminate_process "Input Methods/Meltype.app/Contents/Helpers/MeltypeDictionary.app/", match: :full
    # バンドルが一瞬消える間に macOS が入力ソースの登録を落とすので、登録し直す。
    run "Library/Input Methods/Meltype.app/Contents/MacOS/MeltypeRegisterInputSource",
        args:         ["Library/Input Methods/Meltype.app"],
        base:         :home,
        must_succeed: false
    terminate_process "imklaunchagent"
    terminate_process "TextInputMenuAgent"
  end

  uninstall_preflight_steps do
    terminate_process "Meltype"
    terminate_process "Input Methods/Meltype.app/Contents/Helpers/MeltypeDictionary.app/", match: :full
  end

  zap trash: [
    "~/Library/Application Support/Meltype",
    "~/Library/Preferences/io.github.yksr-melt.inputmethod.Meltype.plist",
  ]

  caveats <<~EOS
    macOS 13 以降が必要です。

    入力ソースへの登録はインストール時に試みますが、失敗した場合はログアウトして
    ログインし直すか、次を実行してから入力メニューで Meltype を選んでください。
      "$HOME/Library/Input Methods/Meltype.app/Contents/MacOS/Meltype" --register-input-source

    署名は ad-hoc で、Apple の公証は受けていません。quarantine 属性はインストール時に
    外しています（Release の SHA-256 は Homebrew が検証します）。

    設定・学習データ (~/Library/Application Support/Meltype) は brew uninstall では消えません。
    消すときは brew uninstall --zap --cask meltype-for-mac です（ユーザー辞書は先に控えを取る）。
  EOS
end
