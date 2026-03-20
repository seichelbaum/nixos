# Creates a small module that allows to set all system specific user options and secrets

{ lib, ... }:

{
  options = {
    ###########################################################################
    # System
    #

    SysConfig.stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "The nixos state version. Check https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion for detail";
      # WARNING: do not define a default here. If this default ever changes, all
      # systems that rely on that default might break!
    };

    SysConfig.hostName = lib.mkOption {
      type = lib.types.str;
      description = "System hostname";
    };

    SysConfig.hostPlatform = lib.mkOption {
      type = lib.types.str;
      description = "The platform of this machine. Usually x86_64-linux. This is used for nixpkgs ...";
      default = "x86_64-linux";
    };

    SysConfig.authorizedKeys = lib.mkOption {
      type = lib.types.listOf (lib.types.str);
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIz2weQ+ATNAbRmMazQrFOW2TdYQj4VlPr+3CuCNiMeb soph@worky"
      ];
      description = "SSH public keys that are authorized by default for the main user and root. This ensures that you can log into that machine.";
    };

    ###########################################################################
    # Main User
    #

    SysConfig.user = {
      realName = lib.mkOption {
        type = lib.types.str;
        description = "The main user's real name";
        default = "Sophia";
      };

      name = lib.mkOption {
        type = lib.types.str;
        description = "The main user's login name";
        default = "soph";
      };

      passHash = lib.mkOption {
        type = lib.types.str;
        description = "The main user's password hash. Use mkpasswd to generate.";
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf (lib.types.str);
        default = [ ];
        description = "The main user's additional groups.";
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf (lib.types.str);
        default = [ ];
        description = "SSH public keys that are authorized by default for this user. Merged with the top-level authorizedKeys.";
      };
    };

    ###########################################################################
    # Root user
    #

    SysConfig.root = {
      passHash = lib.mkOption {
        type = lib.types.str;
        description = "The root user's password hash. Use mkpasswd to generate.";
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf (lib.types.str);
        default = [ ];
        description = "SSH public keys that are authorized by default for this user. Merged with the top-level authorizedKeys.";
      };
    };

    ###########################################################################
    # Hardware:
    #

    SysConfig.hardware.nvidia.prime = {
      intelBusId = lib.mkOption {
        type = lib.types.str;
        description = ''When using NVidia prime, specify the bus ID of the Intel GPU. Use 'nix-shell -p lshw --run "lshw -c display"' to find it.'';
        default = "PCI:0:2:0";
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        description = ''When using NVidia prime, specify the bus ID of the Nvidia GPU. Use 'nix-shell -p lshw --run "lshw -c display"' to find it.'';
        default = "PCI:1:0:0";
      };
    };

    ###########################################################################
    # Features:
    #

    ### Syncthing:

    # A shared Syncthing configuration and a common server is used among all machines.
    # It is on if a server device ID is specified. If not, syncthing will be disabled completely.
    SysConfig.syncthing = {
      devices = {
        serverId = lib.mkOption {
          type = lib.types.str;
          description = "Syncthing main server to use on this system.";
          default = "";
        };

        phoneId = lib.mkOption {
          type = lib.types.str;
          description = "Syncthing ID of the phone to sync photos from/to.";
          default = "";
        };

        pcId = lib.mkOption {
          type = lib.types.str;
          description = "Syncthing ID of the main PC to sync data from/to.";
          default = "";
        };
      };
    };
  };
}
