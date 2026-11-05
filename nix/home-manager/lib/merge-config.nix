{ pkgs, lib }:
{
  name,
  path,
  settings,
  format ? "json",
  empty ? "{}",
  jqOperation ? "$dynamic * $static",
  mode ? "600",
}:
lib.hm.generators.mkImpureConfigMerger {
  inherit
    pkgs
    format
    empty
    jqOperation
    path
    mode
    ;
  staticSettings = (pkgs.formats.${format} { }).generate name settings;
}
