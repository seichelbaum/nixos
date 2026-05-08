# #############################################################################
# Host/Hardware Setup
#
# Hardware: XMG Evo 14 (E25) - AMD CPU and GPU-based laptop

{
  config,
  lib,
  pkgs,
  ...
}:

{
  #############################################################################
  # {{{1 Filesystem Setup
  #

  # NOTE: if those FS are on crypted disks, ensure they are listed in
  # boot.initrd.luks below.

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";

    # No fsck - setting this to true would disable all fsck functionality.
    # DO NOT DO that. Use tune2fs -c -1 and tune2fs -i 0 to disable regular checks instead
    noCheck = false;

    # Mount options
    options = [
      # Avoid a lot of meta data IO
      "noatime"
      # enable TRIM
      "discard"
    ];
  };

  fileSystems."/home" = {
    #device = "/dev/disk/by-label/home";
    device = "/dev/mapper/crypthome";
    fsType = "ext4";

    # No fsck
    noCheck = false;

    # Mount options
    options = [
      # Avoid a lot of meta data IO
      "noatime"
      # enable TRIM
      "discard"
    ];
  };

  # UEFI ESP Partition as Boot partition. The default on NixOS.
  #
  # -> Use a seperate boot. Remember to set efiSysMountPoint in the bootloader
  # config.
  # fileSystems."/boot/efi" = {
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # Swap
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  # Enable periodic TRIM on these? Its an nvme ssd that supports it. Check
  # "lsblk --discard" to validate.
  #
  # Keep in mind: enabling periodic and continuous TRIM (using discard options
  # in fstab and crypttab/initrd luks) at the same time does not make sense.
  # Well, technically. If you forget some "hidden" discard somewhere in the
  # config, it is easy to miss a disk. And it does not cost you anything,
  # especially since it is run every week or so. Just enable it.
  services.fstrim.enable = true;

  # }}}

  #############################################################################
  # {{{ Crypto Setup
  #

  # Refer to the README on how to format LUKS devices and set up keys.

  # Only root is needed for booting. To avoid unlocking home in initrd, it is
  # Listed in crypttab and uses a keyfile to unlock:
  # Create key:
  #   sudo dd if=/dev/random of=/root/crypthome.disk.key bs=4096 count=1
  # Set as Key:
  #   sudo cryptsetup luksAddKey /dev/nvme0n1p3 crypthome.disk.key --iter-time 250
  #
  # NOTE: the options are to optimize for SSD. discard=allow_discards
  environment.etc."crypttab".text = ''
    # <target name>	<source device>		<key file>	<options>
    crypthome /dev/disk/by-uuid/3498deee-ceb9-4550-82a7-d83f70ef6b78 /root/crypthome.disk.key discard,no-read-workqueue,no-write-workqueue
  '';

  # }}}

  #############################################################################
  # {{{ Kernel and Boot Setup
  #

  # Which kernel to use? Zen is quite optimized for desktop use
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

  boot = {
    # Kernel parameters
    kernelParams = [
      # "button.lid_init_state=open"

      #"iommu=soft"

      # This makes some games perform better. But it is hard to find information on
      # what this actually does and how it affects other processes/the system
      # "split_lock_detect=off"

      # Fix the PSR issues - if the screen only refreshes when moving the mouse, use this.
      # Set DC_DISABLE_STUTTER and DC_DISABLE_PSR
      # "amdgpu.dcdebugmask=0x12"
      # Set DC_DISABLE_REPLAY
      # "amdgpu.dcdebugmask=0x400"
      # Set DC_DISABLE_PSR only
      "amdgpu.dcdebugmask=0x10"

      # The default for AMD pstate is "active", Also possible: "passive" and "guided"
      "amd_pstate=guided"
    ];

    # {{{ Initial ramdisk setup
    initrd = {
      # Always loaded from initrd
      kernelModules = lib.mkBefore [
        "amdgpu" # Loaded by default? Handled by hardware.amdgpu.initrd.enable = true
      ];

      # Modules that should be available in the initial ramdisk
      availableKernelModules = [
        # Connectivity
        "thunderbolt"
        "xhci_pci"
        "sdhci_pci"

        # USB HID. To allow USB Keyboards in stage 1 (i.e. LUKS passwords)
        "usbhid"

        # USB Storage. Required if USB Keys should be used for LUKS unlock
        "usbcore"
        "usb_storage"
        "uas"

        # Storage
        "nvme"
        "sd_mod"

        # Crypt hardware support
        "aesni_intel"
        # "crypto_simd"
        "cryptd"

        "kvm-amd"
        "amdgpu"
      ];

      luks.devices = {
        "cryptroot" = {
          device = "/dev/disk/by-uuid/ae4e2cc6-dff7-4742-9d16-0dcf770d5d4a";

          # Supposed to help with ssd
          bypassWorkqueues = true;
          # Enable trim support
          allowDiscards = true;

          # Decrypt using a key file on a USB stick.
          # Create the key (or use the same) as shown above. Write to a stick:
          #   sudo dd if=disk.key of=/dev/sdc
          keyFileSize = 4096;
          keyFileTimeout = 5; # Still allow PW prompt

          # To locate where the file is: either dd it to a partition (makes the
          # rest of the device usable) or to the device itself.
          # Specify the correct device or partition here
          keyFile = "/dev/disk/by-id/usb-Intenso_Micro_Line_23042277610577-0:0-part3";
        };
      };
    };
    # }}}

    # Load these during the second boot stage
    kernelModules = [ ];

    # A list of packages containing additional, required kernel modules
    extraModulePackages = [ ];

    # Blacklist some modules.
    # WARNING: unlike many recommendations online, it is not recommended to
    #          disable uvcvideo or other drivers because they enable power
    #          management! Example: disable uvcvideo and the cam will not power
    #          down.
    blacklistedKernelModules = [ ];
  };

  # }}}

  #############################################################################
  # {{{ Hardware specifics
  #

  # {{{ CPU
  # Update the microcode for AMD CPUs
  hardware.cpu.amd.updateMicrocode = true;

  # Enable the Ryzen SMU driver for better power management and monitoring.
  hardware.cpu.amd.ryzen-smu.enable = true;

  # Allow write-access to CPU MSR
  hardware.cpu.x86.msr = {
    enable = true;
    settings = {
      allow-writes = "on";
    };
  };
  # }}}

  # {{{ GPU

  # see hardware/amdgpu.nix

  # Ensure the amdgpu driver is loaded early to have a proper resolution during
  # boot?
  #
  # - Be aware that this behaves strange from time to time. Sometimes the
  # docked display shows something, sometimes not. Test if you need this! It is
  # sufficient to have it loaded later and used in xserver.
  hardware.amdgpu.initrd.enable = lib.mkDefault true;

  # Explicitly set the video drivers to use.
  services.xserver.videoDrivers = [
    "amdgpu"
    "modesetting"
  ];

  # }}}

  # {{{ Display

  # {{{ VRR

  # Enable variable refresh rate (VRR) support for the built-in display
  services.xserver.deviceSection = ''Option "VariableRefresh" "true"'';

  # # Configure a custom EDID to DISABLE VRR on the internal display.
  # hardware.display.edid = {
  #   enable = true;
  #   packages = [
  #     # Create a custom EDID file for the internal display. Must be a base64 encoded file.
  #     # To get the current EDID:
  #     #   base64 < /sys/class/drm/card1-eDP-1/edid
  #     (pkgs.runCommand "edid-custom" { } ''
  #       mkdir -p "$out/lib/firmware/edid"
  #       base64 -d > "$out/lib/firmware/edid/InternalNoVRR.bin" <<'EOF'
  #       AP///////wAOdzEUAAAAAAAhAQS1HhN4Ai9VplRMmyQNUFQAAAABAQEBAQEBAQEBAQEBAQEBF4hAoLAIbnAwIGYALbwQAAAYAAAA/QAeeObmRgEKICAgICAgAAAA/gBDU09UIFQzICAgICAgAAAA/ABNTkUwMDdaQTMtMgogAbdwIHkCAIEAFXQaAAADUR54AAAAAAAAeAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADfkA==
  #       EOF
  #     '')
  #   ];
  # };
  #
  # # Tell the system to use the custom EDID for the internal display
  # hardware.display.outputs.eDP.edid = "InternalNoVRR.bin";

  # }}}

  # {{{ Color Profile
  #
  # Apply the correct color profile (icm,icc) for this device
  # services.xserver.displayManager.sessionCommands = ''
  #   # load if present
  #   profile=$HOME/.colorprofiles/RazerBlade16_2023/Blade16.icm
  #   if [ -f $profile ]; then
  #     xcalib -output eDP-0 $profile
  #   fi
  # '';
  #
  # }}}

  # {{{ Display Setup with autorandr for Docked/Mobile profiles
  services.autorandr.profiles = {
    "Mobile" = {
      fingerprint = {
        "eDP-1" =
          "00ffffffffffff000e7731140000000000210104b51e1378032f55a6544c9b240d505400000001010101010101010101010101010101178840a0b0086e70302066002dbc10000018000000fd001e78e6e646010a202020202020000000fe0043534f542054330a2020202020000000fc004d4e453030375a41332d320a2001cc7020790200220014bfa10a853f0b9f002f001f0007076d00050005002b000c27001e77000027001e3b0000810015741a000003511e780000000000007800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008b90";
      };
      config = {
        "eDP-1" = {
          enable = true;
          primary = true;
          mode = "2880x1800";
          position = "0x0";
          rate = "120"; # Lower rate saves roughly 1W power on idle.
          dpi = 140;
        };
      };
    };

    "Docked" = {
      fingerprint = {
        "eDP-1" =
          "00ffffffffffff000e7731140000000000210104b51e1378032f55a6544c9b240d505400000001010101010101010101010101010101178840a0b0086e70302066002dbc10000018000000fd001e78e6e646010a202020202020000000fe0043534f542054330a2020202020000000fc004d4e453030375a41332d320a2001cc7020790200220014bfa10a853f0b9f002f001f0007076d00050005002b000c27001e77000027001e3b0000810015741a000003511e780000000000007800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008b90";
        "DP-2" =
          "00ffffffffffff001e6dd25b20b70000041f010380462778ea8cb5af4f43ab260e5054210800d1c06140010101010101010101010101e9e800a0a0a0535030203500b9882100001a000000fd0030901ee63c000a202020202020000000fc004c4720554c545241474541520a000000ff003130344e54504331433838300a013102034cf1230907074d100403011f13123f5d5e5f60616d030c001000b83c20006001020367d85dc401788003e30f00186d1a0000020430900004614f614fe2006ae305c000e606050161614f6fc200a0a0a0555030203500b9882100001a565e00a0a0a0295030203500b9882100001a000000000000000000000000000000e8";
      };
      config = {
        "eDP-1" = {
          enable = false;
          primary = false;
        };
        "DP-2" = {
          enable = true;
          primary = true;
          mode = "2560x1440";
          position = "0x0";
          rate = "120";
          dpi = 96;
        };
      };
    };
  };
  # }}}

  # }}}

  # }}}

  #############################################################################
  # {{{ Power Configuration
  #

  # This is highly specific to the model, your hardware and your usage. A good
  # starting point is to check powertop for a list of tuneables.

  # {{{ General Power Management settings

  # Generally enable some basic power management features
  powerManagement.enable = true;

  # Enable Wifi PowerSave mode. Good idea? Any real use?
  networking.networkmanager.wifi.powersave = true;

  # Powertop can tweak some settings automatically on boot. BUT this can
  # cause some issues with certain hardware. Instead, consider using udev
  # rules and a power manager.
  powerManagement.powertop.enable = false;

  # The kernel sets this to max_performance by default. This machine has
  # two SSD, so setting a more power saving setting can save a few watts!
  #
  # You probably wont need to set this as some power managers (i.e. tlp)
  # will set this automatically, and only when on battery.
  # powerManagement.scsiLinkPolicy = "med_power_with_dipm";

  # Controls how the amd P-States magic works. "powersave" and "performance"
  # are available. Performance is basically the same like "powersave" but with
  # much lower latencies when ramping up the CPU frequency.
  #
  # BUT: when using a power manager like TLP, this will be managed for us.
  # powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  # }}}

  # Nix enables the power profiles tool by default. Unfortunately, it does not
  # switch automatically on bat/ac.
  # See: powerprofilesctl
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.tlp.settings = {
    SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
  };

  # services.cpupower-gui.enable = false;
  #services.auto-cpufreq = {
  #    enable = true;
  #    settings = {
  #      battery = {
  #        governor = "powersave";
  #        turbo = "never";
  #      };
  #      charger = {
  #        governor = "performance";
  #        turbo = "auto";
  #      };
  #    };
  #  };

  boot = {
    # Check the current parameters of a module:
    #   sudo grep -H '' /sys/module/i915/parameters/*
    #  or:
    #   nix-shell -p sysfsutils --run "sudo systool -vm i915"
    # List parameters with description:
    #   modinfo -p i915

    # NEVER: pcie_aspm=force - can cause system freezes
    #kernelParams = [ "pcie_aspm.policy=powersave" ];

    # Some module options
    extraModprobeConfig = ''
      options snd_hda_intel power_save=1

      options iwlwifi power_save=1 power_level=3 uapsd_disable=0
      options iwlmvm power_scheme=2
    '';

    # Some kernel options
    kernel.sysctl = {
      # Power optimizations:
      "kernel.nmi_watchdog" = 0;

      # How long to wait until dirty pages are written to disk.
      # a.k.a.: the amount of work you are willing to loose on power loss.
      # This value is assumed to be "good" by powertop ...
      "vm.dirty_writeback_centisecs" = 1500;

      # Does not make much sense for fast NVMe SSDs
      # "vm.laptop_mode" = 5;

      # Avoid Swap where possible.
      "vm.swappiness" = 1;
    };
  };

  /*
    ASPM
    cat /sys/module/pcie_aspm/parameters/policy
    echo powersave > /sys/module/pcie_aspm/parameters/policy
  */

  /*
    CPU Performance preference
    cat /sys/devices/system/cpu/cpufreq/policy?/energy_performance_available_preferences
    echo "performance" > /sys/devices/system/cpu/cpufreq/policy?/energy_performance_preference
  */

  # Some specific power save rules as well as blacklisting
  services.udev.extraRules = ''
    ## Blacklist autosuspend for some USB devices.

    ## The integrated keyboard. Use lsusb to get the ID for the device.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1532", ATTR{idProduct}=="029f", ATTR{power/autosuspend_delay_ms}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1532", ATTR{idProduct}=="029f", ATTR{power/control}="on"

    ## ALPM (Active Link Power Management) for SATA. The Card Reader. SATA SSD are also supported.
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"

    ## PCI PM

    # blacklist for pci runtime power management for these devices:
    # SUBSYSTEM=="pci", ATTR{vendor}=="0x1234", ATTR{device}=="0x1234", ATTR{power/control}="on", GOTO="pci_pm_end"

    # Enable runtim PM for all other devices
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    LABEL="pci_pm_end"

  '';

  # Undervolting - Be warned: do not overdo. Test the first on a shell:
  # sudo undervolt --core -100 --cache -100 --uncore -100 --gpu -50 --analogio -50
  #services.undervolt = {
  #  enable = true;
  #
  #  uncoreOffset = -100;
  #  coreOffset = -100;
  #  analogioOffset = -50;
  #  gpuOffset = -50;
  #};
  # }}}

  #############################################################################
  # {{{ Other Host Configuration Modules
  #

  # Disabled Plymouth - only works half of the time (when loading amdgpu in initrd)
  boot.plymouth.enable = false;

  imports = [
    # Use Logitech input devices
    ../hardware/logitech-hid.nix
    # Use the Brother scanner
    ../hardware/Brother_ADS-1700W.nix

    # Uses and AMD GPU
    ../hardware/amdgpu.nix
  ];

  # }}}
}
