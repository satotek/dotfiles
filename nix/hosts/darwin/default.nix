{
  inputs,
  self,
  username,
  hostname,
  system,
}:
# システム層 (Homebrew casks, fonts, macOS 設定) のみを管理する。
# ホーム層は homeConfigurations."<user>@<hostname>" (standalone Home Manager,
# sudo 不要の nix-switch) に一本化しているので、ここに home-manager モジュールを
# 入れて二重管理にしないこと。
inputs.nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = {
    inherit
      inputs
      self
      username
      hostname
      ;
  };

  modules = [
    ../../nix-darwin/system.nix
    {
      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };
    }
  ];
}
