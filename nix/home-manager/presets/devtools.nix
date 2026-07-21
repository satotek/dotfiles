{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Nix 版 azure-cli は実行時 `az extension add` が同梱 Python の read-only 制約で
    # 失敗しがちなので、拡張は withExtensions でビルド時に宣言的に焼き込む。
    (azure-cli.withExtensions [
      azure-cli.extensions.azure-devops
      azure-cli.extensions.ssh
      azure-cli.extensions.account
    ])
    bash-language-server
    ffmpeg
    gh
    go
    google-cloud-sdk
    gopls
    hadolint
    lazydocker
    lua-language-server
    marksman
    mermaid-cli
    sops
    shellcheck
    shfmt
    stylua
    tenv # OpenTofu/Terraform 等のバージョンマネージャ。terraform 本体は BSL(unfree)で
    # nixpkgs だと毎回 go build されるため、tenv 経由で公式ビルド済みバイナリを使う。
    terraform-ls
    tflint
  ];
}
