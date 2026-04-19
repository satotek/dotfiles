{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
  };

  xdg.configFile."starship.toml".source = ./files/starship.toml;
}
