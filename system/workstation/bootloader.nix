{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable Systemd in initrd. This, for once, brings up plymouth in stage 1 and
  # allows for some more LUKS specific things at stage 1 (like keyfile from
  # USB/Yubikey)
  boot.initrd.systemd.enable = true;

  # ENable the emergency system and set the one default password.
  boot.initrd.systemd.emergencyAccess = "$y$j9T$J6sXVbrC/yxmzJW0TyckS.$e/tdttyJafXdTGeftQU/5MXvr7uiCpFk5UYjc7fcXU3";

  #############################################################################
  # Bootloader Setup
  #

  # Configure the EFI boot loader.
  boot.loader = {
    # Allow to add an UEFI boot entry
    efi.canTouchEfiVariables = true;

    # Timeout - must be > 0, even if the menu is hidden to make "shift" detectable
    timeout = 1;

    # Use a seperate EFI partition mounted into boot. Requires GRUB.
    # efiSysMountPoint = "/boot/efi";

    # Grub as boot loader
    grub.device = "nodev";
    grub.efiSupport = true;
    # Detect other OS?
    # grub.useOSProber = true;

    # Style - disable the styling
    grub.splashImage = null; # "/sys/firmware/acpi/bgrt/image";
    grub.backgroundColor = null; # "#000000";
    grub.theme = null;

    # Default based on last selection
    grub.default = "saved";

    # Show menu when pressing shift
    grub.extraConfig = ''
      set timeout_style=hidden
    '';

    # Do not list toooo old generations. This does not affect the duration of how
    # long the generations exists. This is up to the garbage collection config.
    grub.configurationLimit = 10;
    systemd-boot.configurationLimit = 10;
  };

  # Some common kernel parameters. Just use it everywhere. You cant read the
  # fast scrolling text anyways.
  boot.kernelParams = [
    # Less talking
    "quiet"

    # Fastboot mode
    "fastboot"

    # Disable the vendor logo because it stays there if booted in the
    # NVIDIA mode (iGPU buffer is never cleared).
    "bgrt_disable"
  ];

  # Be much less noiy while booting. Sets the "loglevel" kernel parameter.
  # 1=KERN_ALERT, 2=KERN_CRIT, 3=KERN_ERR, ... 7=KERN_DBG
  boot.consoleLogLevel = 3;

  #############################################################################
  # Theming Setup
  #

  # Fancy boot screen? Hint: the boot process is fast. You will see this for a
  # few seconds only. There is still some flicker going on :-(.
  boot.plymouth.enable = lib.mkDefault true;

  # Nice themes: https://github.com/adi1090x/plymouth-themes
  #boot.plymouth.theme = "deus_ex";
  boot.plymouth.theme = "spinner_alt";
  boot.plymouth.themePackages = [
    # Only install these. Installing all consumes quite some space
    (pkgs.adi1090x-plymouth-themes.override {
      selected_themes = [
        #"deus_ex",
        "spinner_alt"
      ];
    })
  ];
  # Simplistic:
  # boot.plymouth.theme = "breeze";
  # BGRT (Vendor image). Unfortunately, password prompt looks strange:
  #boot.plymouth.theme = "bgrt";
}
