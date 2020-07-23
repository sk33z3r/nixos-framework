{ pkgs ? import <nixpkgs> {}, DOMAIN }:

{

  # Extra packages
  environment.systemPackages = with pkgs; [
    gotify-cli
  ];

  # Enable gotify-server
  services.gotify = {
    enable = true;
    port = 6000;
  };

  # Generate nginx config
  imports = [
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://127.0.0.1:6000/";
      HOST_HEADER = "$host";
    } )
  ];

}