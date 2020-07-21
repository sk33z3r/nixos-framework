{ config, pkgs, ... }:

{

  # Define common aliases
  programs.fish.shellAliases = {
    dry = "docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock moncho/dry";
  };

  # Install base packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    docker
    docker_compose
  ];

  # Setup cronjobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      "00 04 * * *    root    nix-collect-garbage -d"
      "10 04 * * 6    root    docker image prune -f"
      "20 04 * * 6    root    docker container prune -f"
      "30 04 * * 6    root    docker volume prune -f"
    ];
  };

  # Setup Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;

}