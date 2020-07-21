{ config, pkgs, ... }:

{

  # Extra packages
  environment.systemPackages = with pkgs; [
    ffmpeg detox
  ];

  # Define useful aliases
  programs.fish.shellAliases = {
    dtx = "detox -r *";
  };

}