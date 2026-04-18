{ pkgs, ... }:
{
  home.packages = [ pkgs.wget ];

  xdg.configFile."wget/wgetrc".text = ''
    # Wget configuration file
    # This prevents .wget-hsts from being created in $HOME

    # HSTS database location
    hsts-file = ~/.local/cache/wget-hsts
  '';
}
