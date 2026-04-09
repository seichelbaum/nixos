{
  config,
  lib,
  pkgs,
  ...
}:

{
  #############################################################################
  # Gnome Core
  #

  services.desktopManager.gnome = {
    enable = true;

    # Add some GSettings and custom overrides? Be careful. There are some
    # issues. I.e.:
    # * changing this value is usually set once during first install.
    # If the user overrides it, it is ignored.
    # * This defines the default value only.
    #
    # See https://nixos.org/manual/nixos/unstable/#sec-gnome-gsettings-overrides

    # Allows to set a string to override settings.
    extraGSettingsOverrides = ''
      # Change default terminal for  nautilus-open-any-terminal
      [com.github.stunkymonkey.nautilus-open-any-terminal]
      terminal='kitty'
    '';

    # If a settings should be overwritten in extraGSettingsOverrides, the package
    # that provides the schema must be listed hereL
    extraGSettingsOverridePackages = with pkgs; [
      # A nice way to use a custom terminal for nautilus
      nautilus-open-any-terminal
    ];
  };

  # Configure Gnome services. This allows some detailed settings what to use
  # and what not to use.
  services.gnome = {
    # All the core stuff. These are REQUIRED. Refer to the docs to see a full list.

    # core-shell.enable = false;
    # core-utilities.enable = false;
    # core-os-services.enable = false;
    # glib-networking.enable = false;
    gnome-keyring.enable = true;
    # gnome-settings-daemon.enable = false;
    # tracker.enable = false;
    # tracker-miners.enable = false;
    # gnome-online-miners.enable = false;

    ############################
    # Disable

    # The nautilus preview tools
    sushi.enable = false;

    # An UPNP Mediaserver
    rygel.enable = false;

    # User-level shares
    gnome-user-share.enable = false;

    # Online accounts
    gnome-online-accounts.enable = false;

    # Remote Desktop
    gnome-remote-desktop.enable = false;

    # Setup assitant
    gnome-initial-setup.enable = false;

    # Allow browsers to install shell extensions?
    gnome-browser-connector.enable = false;

    # The games
    games.enable = false;

    # Dev tools
    core-developer-tools.enable = false;

    # Evolution
    evolution-data-server.plugins = lib.mkForce false;
    evolution-data-server.enable = lib.mkForce false;

    # Assistive tools
    at-spi2-core.enable = lib.mkForce false;
  };

  security.pam.services = {
    "${config.SysConfig.user.name}" = {
      # Unlock the user's keyring upon login
      enableGnomeKeyring = true;
    };
  };

  # Exclude all those nasty gnome apps:
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-text-editor
    gnome-photos
    # Useless image viewer
    loupe
    baobab # disk usage analyzer
    cheese # photo booth
    #eog         # image viewer
    epiphany # web browser
    # gedit # text editor
    simple-scan # document scanner
    # totem       # video player
    yelp # help viewer
    #evince      # document viewer
    #file-roller # archive manager
    geary # email client
    # seahorse # password manager
    # these should be self explanatory
    gnome-terminal
    gnome-calculator
    gnome-calendar

    gnome-screenshot
    gnome-disk-utility
    gnome-system-monitor

    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-logs
    #gnome-font-viewer
    gnome-maps
    gnome-music
    gnome-weather

    gnome-connections
  ];

  #############################################################################
  # Additional Gnome-Specific Apps
  #

  environment.systemPackages = with pkgs; [
    # An authentication agent is required for those nice password prompts.
    polkit_gnome

    # Tweak some settings for gnome apps and gtk?
    # Attention: most of the theming settings are IGNORED since Gnome 43.
    # gnome.gnome-tweaks

    # gsettings editor
    dconf-editor

    # Support python-based Nautilus extensions
    nautilus-python

    # Allows to open an arbitrary terminal instead of kgx (gnome terminal)
    # Configure via
    # gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty
    nautilus-open-any-terminal

    # much more useful in comparison to loupe
    eog

    # Showtime video player is trash. Basic functionality is missing.
    totem

    # archive manager
    file-roller
  ];

  # Required for some apps to work (to be able to query settings)
  programs.dconf.enable = true;

  #############################################################################
  # Polkit Agent Setup
  #

  # Unfortunately, its xdg autostart only runs on gnome directly. Use a simple
  # systemd service to fix that for other window managers
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  #############################################################################
  # GStreamer Plugins for Totem
  #
  # Just installing the plugins is not enough. Gnome apps like Totem
  # require the GST_PLUGIN_SYSTEM_PATH_1_0 variable to be set properly.
  #
  # See:
  #  * https://github.com/NixOS/nixpkgs/issues/53631
  #  * https://github.com/NixOS/nixpkgs/issues/195936
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
      [
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-ugly
        pkgs.gst_all_1.gst-libav
      ];

}
