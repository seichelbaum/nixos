{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ATTENTION: this defines some basic system services.
  # DO NOT: no user or machine specific services!

  #############################################################################
  # Systemd & Journal  Setup
  #

  # Set the timeout of SystemD to 30s. Default is 90s.
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
  };

  # Journal keeps growing and growing. Limit.
  services.journald.extraConfig = "SystemMaxUse=100M";
  systemd.coredump = {
    # Needs to be enabled or the kernel throws the dumps into the process directory
    # NOTE: if false, the dumps will be placed in the process' cwd -> will clutter the filesystem!
    enable = lib.mkDefault true;
    # Tell systemd where to keep those: none - disabled, journal - store alongside the journal, external - store in /var/lib/systemd/coredump.
    # Journal is usually a good choice. The Journal rotation rules apply so we do not store hundresd
    # MaxUse defines the max size of dump storage if "external"
    settings.Coredump = {
      Storage = "journal";
      MaxUse = "256M";
    };
  };

  # Logrotate - needed?
  #services.logrotate.enable =true;

  #############################################################################
  # SSH
  #

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.openssh = {
    enable = true;

    # Definitely needed
    allowSFTP = true;

    # Disallow password login.
    settings.PasswordAuthentication = false;

    # Should root be allowed to ssh into the machine?
    settings.PermitRootLogin = "prohibit-password"; # "no"

    # NOTE: To modify Kex/Cipher/HostKey algorithms, check the quirks/Brother
    # file. Avoid fiddling in here. The defaults are SAFE defaults.
  };

  #############################################################################
  # Others
  #

  # Locate service
  services.locate = {
    enable = true;
    # package = pkgs.mlocate;
    # Default is during the night and will never trigger on a desktop that is off.
    interval = "12:00";
  };

}
