{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hadolint
    lazydocker
    postgresql
    # OpenTofu/Terraform 等のバージョンマネージャ。terraform 本体は BSL(unfree)で
    # nixpkgs だと毎回 go build されるため、tenv 経由で公式ビルド済みバイナリを使う。
    tenv
    terraform-ls
    tflint
  ];
}
