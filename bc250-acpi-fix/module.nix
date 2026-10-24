{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bc250-acpi-fix;

  # nixpkgs 26.11 removed this option (systemd initrd is always used) and reading it throws.
  systemdInitrd =
    let
      r = builtins.tryEval config.boot.initrd.systemd.enable;
    in
    !r.success || r.value;
in
{
  options.services.bc250-acpi-fix = {
    enable = lib.mkEnableOption "BC-250 ACPI table overrides for CPU idle states and frequency scaling";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Package providing the BC-250 ACPI override tables.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = systemdInitrd -> config.boot.loader.supportsInitrdSecrets or true;
        message = "services.bc250-acpi-fix requires an initrd the bootloader loads unmodified.";
      }
    ];

    boot.initrd.prepend = [
      "${cfg.package}/lib/firmware/acpi/acpi_override.cpio"
    ];
  };
}
