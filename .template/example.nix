{ config, lib, pkgs, ... }:

let

  username = "username";
  home = "/home/username";
  staticConf = import ./framework/nginx/static.nix;
  proxyConf = import ./framework/nginx/proxy.nix;
  redirectConf = import ./framework/nginx/redirect.nix;
  wordpressConf = import ./framework/docker/wordpress.nix;

in

{

  imports =
  [
    # Base system definitions
    ( import ./framework/nixos/user.nix { USER = "${username}"; HOME_DIR = "${home}"; } )
    ./framework/base.nix
    ./framework/nginx.nix

    # NixOS service definitions
    ( import ./framework/nixos/syncthing.nix {
      DOMAIN = "sync.example.tld";
      USER = "${username}";
      GROUP = "users";
      HOME_DIR = "${home}";
      SYNC_DIR = "${home}/sync";
    } )

    # Gitea setup
    ( import ./framework/docker/gitea.nix { DOMAIN = "git.example.tld"; } )
    ./web-hooks.nix

    # Docker service definitions
    ./framework/docker/minecraft.nix
    ./framework/docker/terraria.nix
    ( import ./framework/docker/mail.nix {
      DOMAIN = "mail.example.tld";
      DOMAINS_SERVED = "mail.example.tld mail.client01.com";
    } )
    ( import ./framework/docker/wiki.nix { DOMAIN = "wiki.example.tld"; } )
    ( import ./framework/docker/seafile.nix {
      DOMAIN = "files.example.tld";
      EMAIL = "dude@example.tld";
      PASS = "super-secret";
    } )
    ( import ./framework/docker/heimdall.nix { DOMAIN = "home.example.tld"; } )

    # Generic vhost definitions
    ( staticConf { DOMAIN = "example.tld"; } )
    ( staticConf { DOMAIN = "client01.com"; } )
    ( redirectConf {
      SOURCE = "client01.net";
      DEST = "client01.com";
    } )

    # Wordpress definitions
    ( wordpressConf {
      CLIENT = "blogger";
      DOMAIN = "bloggersname.com";
      IP4 = "100";
      SQL_IP = "101";
      SQL_ROOT = "hiddensecret01";
      SQL_PASS = "hiddensecret02";
    } )
  ];

  networking.hostName = "machine-hostname";

}