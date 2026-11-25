{ lib, pkgs, ... }:
let
  kache = lib.getExe pkgs.kache;
in
{
  home.packages = [ pkgs.kache ];

  # rustcの前に挟み、worktreeやプロジェクトをまたいで同じ依存のビルド結果を
  # ハードリンクで使い回す。~/.cargo/config.tomlのbuild.rustc-wrapperではなく
  # 環境変数にするのは、キャッシュを避けたいツールがRUSTC_WRAPPERを外せるようにするため。
  # profile.nixがsystemdとlaunchdにも渡すので、サーバー経由で動くエージェントにも効く。
  home.sessionVariables.RUSTC_WRAPPER = kache;

  # ディスクは125GB程度なので、キャッシュの上限と空き容量の下限は控えめにする。
  xdg.configFile."kache/config.toml".source = (pkgs.formats.toml { }).generate "kache-config.toml" {
    cache = {
      local_max_size = "20GiB";
      auto_clean_idle_targets_days = 14;
      auto_recover_min_free_bytes = "20GiB";
      auto_recover_targets = true;
    };
  };

  # 上の上限や古いtarget/の削除はデーモンが行う。動いていないと何も消されない。
  systemd.user.services.kache = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit.Description = "kache build cache daemon";
    Service = {
      ExecStart = "${kache} daemon run";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  launchd.agents.kache = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        kache
        "daemon"
        "run"
      ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 5;
    };
  };
}
