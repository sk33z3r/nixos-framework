{ config, pkgs, ... }:

{

  # Extra packages
  environment.systemPackages = with pkgs; [
    ipfs ipget
  ];

  # Enable the service
  services.ipfs = {
    enable = true;
    gatewayAddress = "/ip4/0.0.0.0/tcp/9393";
  };

}