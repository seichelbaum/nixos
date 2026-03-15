# ############################################################################
# The base setup for all desktops
#

{
  config,
  lib,
  pkgs,
  ...
}:

{

  #############################################################################
  # {{{ Awesome
  #

  # Build the latest awesome
  services.xserver.windowManager.awesome = {
    enable = true;
    # package = pkgs.awesome.overrideAttrs (old: {
    #   src = pkgs.fetchFromGitHub {
    #     owner = "awesomeWM";
    #     repo = "awesome";
    #     rev = "e6f5c7980862b7c3ec6c50c643b15ff2249310cc";
    #     # Set this. Nix will complain and show the real hash
    #     #sha256 = "sha256:0000000000000000000000000000000000000000000000000000";
    #     sha256 = "sha256-afviu5b86JDWd5F12Ag81JPTu9qbXi3fAlBp9tv58fI=";
    #   };
    #
    #   patches = [ ];
    #
    #   # Man and doc generation fails right now
    #   cmakeFlags = old.cmakeFlags
    #     ++ [ "-DGENERATE_MANPAGES=OFF" "-DGENERATE_DOC=off" ];
    # });
  };

  # }}}

  #############################################################################
  # {{{ Services and background programs to run per desktop session
  #

  # Clipboard manager
  services.greenclip.enable = true;

  # Light control
  hardware.acpilight.enable = true;

  # The GPG agent to store unlocked keys per session
  programs.gnupg.agent.enable = true;

  # Ensure autorandr restarts awesome to pick up changes like active screen and DPI changes.
  services.autorandr.hooks.postswitch = {
    "50_awesomeRestart" = ''
      awesome-client "awesome.restart()" > /dev/null 2>&1
      sleep 1
    '';
  };

  # }}}

  #############################################################################
  # {{{ Desktop baseline programs
  #

  # Enable firefox by default.
  programs.firefox.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    # Nice terminal
    kitty

    # xranr frontend
    arandr

    # Notifications
    dunst
    libnotify

    # Launchers
    rofi

    # Allow to ask for passwords graphically
    pinentry-gnome3

    # Nice screen locker
    xss-lock
    # shows a blurred screen.
    # i3lock-fancy-rapid
    # Super secure
    xsecurelock

    # Power monitor
    powertop
  ];

  # Make kitty the default for those that respect the TERMINAL variable
  environment.variables = {
    TERMINAL = "${pkgs.kitty}/bin/kitty";
  };

  # }}}

  #############################################################################
  # {{{ Locking, Dimming an DPMS
  #

  # xss-lock as the locking service
  programs.xss-lock = {
    enable = true;
    #lockerCommand = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 5 5";
    lockerCommand = "${pkgs.xsecurelock}/bin/xsecurelock";
    extraOptions = [
      # Dimmer scripts
      "-n"
      #"/home/${config.SysConfig.user.name}/.local/bin/mon-backlight-dimmer"
      "${pkgs.xsecurelock}libexec/xsecurelock/dimmer"

      # Ensures the machine goes to sleep after locking the screen. Important on laptops.
      "-l"
    ];
  };

  # To configure the lock timeouts, use xset:
  services.xserver.displayManager.sessionCommands = ''
    # Enable DPMS and set timeouts
    xset +dpms
    xset dpms 600 600 600

    # Start blank after 180s, lock after additional 4xx seconds.
    #
    # The first number is the noification period. xss-lock
    # calls its notifier in that case. It is used to dim the
    # screen. If xss-lock is not running, the screen blanks.
    #
    # The second number triggers after the notification and
    # usually locks.
    xset s 180 400
  '';

  # }}}
}
