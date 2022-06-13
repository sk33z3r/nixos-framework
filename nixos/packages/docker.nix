{ config, pkgs, ... }:

{

  # Filesystem setup
  system.activationScripts.docker-builds = {
    text = ''
      mkdir -p /build
    '';
    deps = [];
  };

  # Define common aliases
  programs.fish.shellAliases = {
    dry = "docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock moncho/dry";
  };

  # Install base packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
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

  # Custom automated docker image update loop
  environment.etc."docker-update.sh" = {
    uid = 1000;
    gid = 100;
    mode = "0755";
    text = ''
      #!/usr/bin/env bash
      for i in `docker ps | awk '{print $(NF)}' | grep -v mailcow | grep -v terraria | grep -v "\-db" | grep -v _mysql | grep -v NAMES`; do
        $i update
      done
    '';
  };

  # Setup Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;

}