# #############################################################################
# Common Desktop Baseline
#

{ config, lib, pkgs, ... }:

{
  #############################################################################
  # Absolute baseline for a desktop.
  #

  environment.systemPackages = with pkgs; [

    # Company fonts - I use these for some work-related things
    montserrat
    raleway

    ###########################################################################
    # Graphics, Office work, Productivity
    #

    gimp
    inkscape
    blender

    libreoffice

    standardnotes

    ###########################################################################
    # Utils
    #

    speedcrunch
    flameshot

    imagemagick
    ghostscript # needed for imagemagick and pdf stuff
    ocrmypdf
    pandoc

    ffmpeg-full
    yt-dlp

    # Partitioning and file system stuff
    gparted
    exfatprogs
    ntfs3g
    cifs-utils

    proton-pass
    proton-authenticator

    ###########################################################################
    # Communication tools
    #

    # Ferdium replaces rocketchat-desktop, slack, discord, ...
    ferdium
    protonmail-desktop
    signal-desktop
    thunderbird

    ###########################################################################
    # Entertainment

    spotify
    vlc

    # Sometimes works better for streamed media consumption
    google-chrome
  ];

  #############################################################################
  # Firefox - default browser
  #

  # Firefox by default, some options pre-set.
  programs.firefox = {
    enable = true;

    # Native hosts:
    # nativeMessagingHosts.packages = with pkgs; [ passff-host tridactyl-native ];

    # Note: this is not the dictionary list.
    languagePacks = [ "en-US" "de" ];

    # Do not overdo it. Most important stuff is synced with Firefox Sync anyway
    preferences = { "browser.tabs.closeWindowWithLastTab" = false; };
  };
}
