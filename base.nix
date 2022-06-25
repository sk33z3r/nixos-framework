{ config, pkgs, ... }:

{

  # Import generated hardware config
  imports = [ /etc/nixos/hardware-configuration.nix ];

  # Setup BIOS and Grub2
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";

  # Filesystem setup
  system.activationScripts.base = {
    text = ''
      mkdir -p /backups
    '';
    deps = [];
  };

  # Define common aliases
  programs.fish.shellAliases = {
    ll = "ls -lh";
    l1 = "ls -1";
    la = "ls -lah";
    c = "clear";
  };

  # Install base packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    fail2ban
    wget
    vim
    git
    htop
    pciutils
    nmap
    openssl
    tmux
    nload
    mysql
    nfs-utils
    jq
    fish
    byobu
    inotify-tools
    tcptrack
    ncdu
    zip
    unzip
    imagemagick
  ];

  # Enable fail2ban
  services.fail2ban.enable = true;

  # SSHD Config
  services.openssh = {
    enable = true;
    kbdInteractiveAuthentication = false;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  # Setup global user defaults
  time.timeZone = "UTC";
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "22.05"; # Did you read the comment?

}