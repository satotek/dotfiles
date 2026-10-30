cask "herdr-app" do
  version "0.1.9"
  sha256 "7cd783d6cd98e050d7cb43bc43d7facc387d300b5b5e93c7376596b5d8727231"

  url "https://releases.herdr.dev/app/#{version}/herdr-app-macos-aarch64.tar.gz"
  name "Herdr"
  desc "Desktop app for terminals and coding agents"
  homepage "https://herdr.dev/"

  # 上流の macOS ビルドは Apple Silicon のみ。Intel Mac はソースビルドが必要。
  depends_on arch: :arm64
  depends_on macos: ">= :big_sur"

  app "Herdr.app"

  # 上流 installer と同じ名前で CLI（herdr-app ls など）を使えるようにする。
  binary "#{appdir}/Herdr.app/Contents/MacOS/Herdr", target: "herdr-app"
end
