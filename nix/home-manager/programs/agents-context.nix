{ lib, ... }:
let
  # agents/AGENTS.md と agents/rules/*.md を 1 枚に連結して全エージェントに配る。
  # Codex には @import が無いため、Claude も同じ連結結果を読ませて内容を揃える。
  agentsDir = ../../../agents;
  rulesDir = agentsDir + "/rules";
  ruleFiles = lib.sort lib.lessThan (
    lib.filter (name: lib.hasSuffix ".md" name) (lib.attrNames (builtins.readDir rulesDir))
  );
  context = lib.concatMapStringsSep "\n" builtins.readFile (
    [ (agentsDir + "/AGENTS.md") ] ++ map (name: rulesDir + "/${name}") ruleFiles
  );
in
{
  programs.claude-code.context = context;
  programs.codex.context = context;

  # home-manager にモジュールが無いエージェントは、グローバルの指示ファイルを直接置く。
  # OpenCode は設定ディレクトリの AGENTS.md、grok は ~/.grok/AGENTS.md、
  # Antigravity CLI は ~/.gemini/{GEMINI,AGENTS}.md をグローバルルールとして読む。
  xdg.configFile."opencode/AGENTS.md".text = context;
  home.file.".grok/AGENTS.md".text = context;
  home.file.".gemini/AGENTS.md".text = context;
}
