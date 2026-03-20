{
  config,
  lib,
  pkgs,
  ...
}:

{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  #
  # Refer: https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = config.SysConfig.stateVersion;

  #############################################################################
  # NixOS Base Setup
  #

  # Do not install the docs of packages and nix by default. This saves a lot
  # of memory.
  documentation.nixos.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;
  documentation.dev.enable = false;
  # ... Except man pages
  documentation.man.enable = true;

  #############################################################################
  # Nix Tools
  #

  # Install some nix tools.
  environment.systemPackages = with pkgs; [
    # Handy tool to print nixos options.
    # Examples:
    #    * print the nested options of 'documentation.man': nixos-option documentation.man
    #    * print the value of an option in the config and where it was set: nixos-option documentation.man.enable
    nixos-option

    # TUI to browse through the store and search for packages.
    nix-tree

    # Code formatter for nix.
    nixfmt
  ];

  #############################################################################
  # Nix Base Setup
  #

  # Generally allow unfree software
  nixpkgs.config.allowUnfree = true;
  # Hardware Platform
  nixpkgs.hostPlatform = config.SysConfig.hostPlatform;

  # Ensure all terminfo are installed to avoid ssh-ing into a machine that
  # does not understand your terminal. I.e. kitty uses zterm-kitty that would
  # trigger an invalid term definition alert.
  environment.enableAllTerminfo = lib.mkDefault true;

  # Provide an nix package file index. If you need to know which package contains a file, use this.
  # Example:
  #   * nix-locate 'bin/hello' - list packages that contain a bin/hello file
  #
  # After enabling, be patient. An index has to be built and this can take a while.
  programs.nix-index.enable = true;

  #############################################################################
  # Nix house-holding Setup
  #

  # Nix Package Manager optimization and garbage colection
  nix = {
    settings = {
      # Optimise store at every build
      auto-optimise-store = true;
    };

    # Automatic garbage collection ever week
    gc = {
      automatic = true;
      dates = "weekly";
      # Delete all generations older than x,
      options = "--delete-older-than 14d";
    };
  };

  #############################################################################
  # Nix Features
  #

  nix.settings.experimental-features = [
    # To enable the nice experimental nix command features
    "nix-command"

    # Flakes support
    "flakes"
  ];

  # Disable the warning that shows when using a flake in a dirty git repo. As I use flakes mostly for dev-envs, they are
  # nearly always dirty.
  nix.settings.warn-dirty = false;

  #############################################################################
  # Quirks and hacks
  #

  # On nix, /bin/bash does not exists. As shebang, `#!/usr/bin/env bash` is recommended instead.
  # Unfortunately, we cannot influence this on external scripts written by others.
  #
  # This links bin/sh to bin/bash to make it work
  system.activationScripts.binbash = {
    deps = [ "binsh" ];
    text = ''
      ln -sf /bin/sh /bin/bash
    '';
  };
}
