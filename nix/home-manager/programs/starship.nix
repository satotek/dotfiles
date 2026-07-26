{ config, pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = false;
      format = "$os$directory$git_branch$git_commit$git_metrics$git_state$git_status$fill$python$nodejs$line_break$character";
      right_format = "$cmd_duration$memory_usage$battery$time";

      fill.symbol = " ";

      os = {
        disabled = false;
        style = "bg:surface0 fg:text";
        symbols = {
          AIX = " ";
          AlmaLinux = " ";
          Alpaquita = " ";
          Alpine = " ";
          ALTLinux = " ";
          Amazon = " ";
          Android = " ";
          AOSC = " ";
          Arch = " ";
          Artix = " ";
          Bluefin = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Elementary = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = " ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = " ";
          InstantOS = " ";
          Ios = "󰀷 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = " ";
          OpenCloudOS = " ";
          openEuler = " ";
          openSUSE = " ";
          OracleLinux = "󰺡 ";
          PikaOS = " ";
          Pop = " ";
          Raspbian = " ";
          Redhat = "󱄛 ";
          RedHatEnterprise = "󱄛 ";
          Redox = "󰀘 ";
          RockyLinux = " ";
          Solus = " ";
          SUSE = " ";
          Ubuntu = " ";
          Ultramarine = " ";
          Unknown = " ";
          Uos = " ";
          Void = " ";
          Windows = "󰍲 ";
          Zorin = " ";
        };
      };

      directory = {
        truncate_to_repo = false;
        truncation_length = 6;
        truncation_symbol = "…/";
        home_symbol = "~";
        read_only = " 󰌾";
        format = "[  $path]($style)[$read_only]($read_only_style) ";
        style = "bold cyan";
        read_only_style = "bold cyan";
      };

      nodejs = {
        disabled = true;
        format = "[$symbol]($style) ";
        symbol = " ";
        style = "green";
      };

      python = {
        disabled = false;
        format = "[\${symbol}(\\($virtualenv\\))]($style) ";
        symbol = " ";
        style = "yellow";
        python_binary = "python3";
      };

      git_branch.disabled = false;
      git_commit.disabled = false;
      git_metrics.disabled = false;
      git_state.disabled = false;
      git_status.disabled = false;

      cmd_duration = {
        min_time = 500;
        format = "took [  $duration]($style) ";
        style = "bold yellow";
      };

      memory_usage = {
        disabled = false;
        threshold = -1;
        format = "[$symbol$ram_pct]($style) ";
        symbol = "󰍛 ";
        style = "bold white";
      };

      battery = {
        disabled = false;
        format = "[$symbol$percentage]($style) ";
        full_symbol = "󰁹 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󰂃 ";
        unknown_symbol = "󰂑 ";
        empty_symbol = "󰂎 ";
        display = [
          {
            threshold = 100;
            style = "bold white";
          }
        ];
      };

      time = {
        disabled = false;
        time_format = "%T";
        format = "[  $time]($style)";
        style = "bold blue";
      };

      character.disabled = false;
    };
  };

  # Nix storeのmtimeでは設定変更を確実に検出できないため、Home Managerの
  # 内容比較でstarship.tomlが変わった場合は、次回起動時にinitを再生成する。
  home.file."${config.xdg.configHome}/starship.toml".onChange = ''
    ${pkgs.coreutils}/bin/rm -f \
      "${config.home.homeDirectory}/.local/cache/zsh/starship.zsh" \
      "${config.home.homeDirectory}/.local/cache/zsh/starship.path"
  '';
}
