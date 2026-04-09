# #############################################################################
# AI tools and UIs
#

{
  config,
  lib,
  pkgs,
  ...
}:
{

  environment.systemPackages = with pkgs; [

    ###########################################################################
    # Standard tools
    #

    ollama-rocm

    ###########################################################################
    # AI TUI/UI
    #

    # Nice tool for interacting with AI chat models from the terminal
    aichat

  ];

  # Open WebUI is nice for local LLMs
  # services.open-webui = {
  #   enable = true;
  #   openFirewall = true;
  #
  #   environment = {
  #     OLLAMA_API_BASE_URL = "http://127.0.0.1:11435";
  #     # Disable authentication
  #     WEBUI_AUTH = "False";
  #   };
  # };
}
