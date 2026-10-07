{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";

  # 未ステージ分を stash すると戻すときに整形結果と衝突しうるため、index を直接整形する。
  # nixfmt は formatter (nixfmt-tree) と同じ pkgs のものを使い、結果を一致させる。
  preCommit = pkgs.writeShellApplication {
    name = "dotfiles-pre-commit";
    runtimeInputs = [
      pkgs.git
      pkgs.nixfmt
    ];
    text = ''
      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT
      status=0

      while IFS= read -r -d "" path; do
        if ! git cat-file blob ":$path" | nixfmt --filename="$path" >"$tmp"; then
          echo "pre-commit: nixfmt failed on $path" >&2
          status=1
          continue
        fi

        old="$(git rev-parse ":$path")"
        new="$(git hash-object -w "$tmp")"
        [ "$old" = "$new" ] && continue

        if git diff --quiet -- "$path"; then
          cat "$tmp" >"$path"
        else
          echo "pre-commit: formatted the staged $path; its unstaged copy is left as is" >&2
        fi
        mode="$(git ls-files --stage -- "$path" | cut -d' ' -f1)"
        git update-index --cacheinfo "$mode,$new,$path"
        echo "pre-commit: formatted $path" >&2
      done < <(git diff --cached --name-only --diff-filter=ACMR -z -- '*.nix')

      exit "$status"
    '';
  };
in
{
  # .git/hooks は clone で配られないため、switch のたびに置く。
  home.activation.installDotfilesGitHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if hooks_dir="$(${pkgs.git}/bin/git -C ${lib.escapeShellArg dotfilesDir} rev-parse --git-common-dir 2>/dev/null)/hooks"; then
      case "$hooks_dir" in
        /*) ;;
        *) hooks_dir=${lib.escapeShellArg dotfilesDir}/"$hooks_dir" ;;
      esac
      hook="$hooks_dir/pre-commit"
      if [ -e "$hook" ] && [ ! -L "$hook" ]; then
        warnEcho "Skipping $hook: a hook that is not managed by Home Manager already exists"
      else
        run mkdir -p "$hooks_dir"
        run ln -sfn ${lib.getExe preCommit} "$hook"
      fi
    fi
  '';
}
