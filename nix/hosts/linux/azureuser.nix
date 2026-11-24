{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "azureuser";
  homeDirectory = "/home/azureuser";
  extraModules = [
    ../../home-manager/platforms/linux.nix
  ]
  ++ (import ../../home-manager/roles.nix).select [
    "base"
    "dev"
    "rust"
    "ai"
    "secrets"
  ]
  # Orca と T3 Code のサーバー、そこへ届く tailnet の口は gem-ai だけ。
  # CLI と settings.json は ai preset で全ホストに入る。
  ++ (
    if hostname == "gem-ai" then
      [
        ../../home-manager/programs/orca-server.nix
        ../../home-manager/programs/t3code-server.nix
        ../../home-manager/programs/tailscale.nix
        ../../home-manager/programs/zsh-history-check.nix
        {
          # rex.service はユーザーサービスなので、linger が無いとログアウトで
          # サーバーごと止まり、セッションも消える。linger はユーザー単位の
          # システム設定で Home Manager では宣言できないため、手動で
          # `loginctl enable-linger` を実行済み。VM を作り直したら再実行すること。
          # `rex server tailscale on` は再起動をまたいで残らず、VM の停止ごとに
          # tailnet から消えるので、サーバーの起動フラグで有効にする。
          # 名前を変えると別ノードとして登録し直しになるため、既存の名前に合わせる。
          services.rex.tailscale = {
            enable = true;
            hostname = "gem-ai-rex";
          };
        }
      ]
    else
      [ ]
  );
}
