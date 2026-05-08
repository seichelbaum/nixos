{
  lib,
  ...
}:

{
  #############################################################################
  # Common Base Setup
  #

  # Make the hardware clock local time. This fixes the time difference issues with windows
  time.hardwareClockInLocalTime = true;

  #############################################################################
  # Firmware things
  #

  # In general, load and apply firmware (like intel microcode, iwlwifi firmware, ...)
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # Microcode updates? False by default - they consume quite some space.
  # Enable the correct one in the machine-specific config.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault false;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault false;

  # Firmware update daemon.
  services.fwupd.enable = lib.mkDefault true;
}
