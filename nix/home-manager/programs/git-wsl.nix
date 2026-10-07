{ config, ... }:
let
  windowsApps = "/mnt/c/Users/konos/AppData/Local/Microsoft/WindowsApps";

  # 署名の検証も Windows 側の op-ssh-sign-wsl.exe が行う。あれは WSL のパス変換で
  # Linux のパスは読めるが、その先の Linux symlink を辿れない。home.file は必ず
  # symlink を張るため ~/.config/git/allowed_signers を渡すと開けずに失敗し、
  # 署名があるのに "No signature" と表示される。store の実ファイルを直接指す。
  allowedSigners = config.home.file.".config/git/allowed_signers".source;
in
{
  # 公式 WSL 連携で Windows の 1Password に認証と署名を依頼する。
  # WSL の ssh は Windows の名前付きパイプに届かないが、Windows の ssh.exe は
  # 同じ OS 上の 1Password エージェントを直接叩けるので、橋渡しは要らない。
  programs.git.settings = {
    core.sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
    gpg = {
      format = "ssh";
      ssh = {
        program = "${windowsApps}/op-ssh-sign-wsl.exe";
        allowedSignersFile = "${allowedSigners}";
      };
    };
    # エージェントには 8 本の鍵が入っており、先頭が GitHub 用とは限らない
    # (今は "GCP nosuke-net")。macOS 側と同じ "Github" 鍵を明示する。
    # 公開鍵は秘匿情報ではなく、既に git.nix と GitHub 側に出ている。
    user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEu/vDcjBdXbzqM6e6V56JX65xkjyK7Z6sDvnfeCTXLU";
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
}
