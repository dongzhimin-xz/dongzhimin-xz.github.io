{ pkgs ? import <nixpkgs> { system = "i686-linux"; } }:
let
  inherit (pkgs) lib;
in
(pkgs.pkgsCross.gnu64.linux.override (args: {
  enableCommonConfig = false;
  structuredExtraConfig =
    let
      lines = lib.splitString "\n" (lib.readFile ./config);
      attrs =
        builtins.filter
        (x: x != null)
        (
          map
          (line:
            if lib.hasSuffix "is not set" line
            then { name = (lib.removePrefix "# CONFIG_" (lib.removeSuffix " is not set" line)); value = lib.mkForce lib.kernel.no; }
            else
              if lib.hasSuffix "=y" line
              then { name = (lib.removePrefix "CONFIG_" (lib.removeSuffix "=y" line)); value = lib.mkForce lib.kernel.yes; }
              else null
          )
          lines
        );
    in
    (lib.listToAttrs attrs) // {
      RUST = lib.mkForce lib.kernel.no;
      MODULES = lib.mkForce lib.kernel.no;

      # Add -64 to the hostname to make it easier to see which kernel is running during development
      DEFAULT_HOSTNAME = lib.mkForce (lib.kernel.freeform "live-bootstrap-64");
    };
  ignoreConfigErrors = true;
})).overrideAttrs (attrs: {
  # postInstall should be disabled if MODULES is set to no, but that doesn't seem to work.
  # Because it isn't used otherwise, we can just override it with an empty string here.
  postInstall = "";
})
