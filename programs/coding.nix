# #############################################################################
# Work related stuff
#

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Ensure that all runtimes are enabled. Neovim itself is enabled as system default
  # editor already.
  programs.neovim = {
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  # Git, git lfs
  programs.git.lfs.enable = true;
  programs.git.enable = true; # Enabled in the common system config

  # Nore
  environment.systemPackages = with pkgs; [

    ###########################################################################
    # Editors
    #

    # VS Code is working well with unity and has good C# support out of the box
    vscode

    ###########################################################################
    # Standard tools
    #

    git-lfs

    # NOTE: do not install any compiler here. Use devbox/devenv/shell.nix for
    # projects instead.

    # One exception though: the system gcc - although devbox/devenv should
    # provide these for projects, it helps to build wheels with pip for
    # example. This ensures the lib versions match.
    gcc
    gnumake
    gdb

    # Formatters, linters and LSP

    ## > C++
    clang-tools # includes linter, language server
    cmake-format
    cmake-language-server

    ## > Web stuff
    typescript-language-server
    vue-language-server
    prettier
    vscode-json-languageserver

    ## > Scripting and system stuff
    stylua
    lua-language-server
    nixd
    nixfmt
    shfmt
    bash-language-server

    ## > Python
    isort
    black

    # Very nice for big directory comparisons
    meld
    gittyup

    ###########################################################################
    # Development: Unity
    #

    # Ensure some mandatory packages are in unity's path
    (unityhub.override {
      extraLibs =
        pkgs: with pkgs; [
          # Without this, the vulkan libs will not be found -> no vulkan
          # renderer in unity (required for HDRP)
          vulkan-loader

          # Pre 2022.3 versions require this:
          # openssl_1_1

          # To ensure unity finds VS Code in its path
          vscode
        ];
    })

    # Dotnet SDK is required if VS Code C# extensions should be used
    dotnet-sdk_8

    ###########################################################################
    # Development: GPU Programming - Cuda/ROCm
    #

    # NOTE: I chose to install these in the flake/direnv of projects that need them
    # cudatoolkit
    # rocmPackages.rocm-runtime

    ###########################################################################
    # Development: Android
    #

    # ADB and fastboot. Not only used for Android development.
    android-tools

    #android-studio
    #android-studio-tools

  ];

  # Needed for Unity Editor pre 2022.3.1f1 - REMOVE as soon as possible.
  # nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1v" ];
}
