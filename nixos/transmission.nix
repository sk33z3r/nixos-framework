{ DOMAIN, WEB_USER, WEB_PASS, DOWNLOADS }:

let

  WORKDIR = "/transmission";

in

{

  # Filesystem setup
  system.activationScripts.transmission = {
    text = ''
      mkdir -p ${DOWNLOADS}
      mkdir -p ${WORKDIR}/.incomplete
    '';
    deps = [];
  };

  # Extra aliases
  programs.fish.shellAliases = {
    transmission = "/etc/transmission.sh";
  };

  # Open extra ports
  networking.firewall = {
    allowedTCPPorts = [ 51413 ];
    allowedUDPPorts = [ 51413 ];
  };

  # Setup transmission
  services.transmission = {
    enable = true;
    user = "root";
    group = "root";
    home = "${WORKDIR}";
    port = 8888;
    settings = {
      download-dir = "${DOWNLOADS}";
      incomplete-dir = "${WORKDIR}/.incomplete";
      incomplete-dir-enabled = true;
      rpc-whitelist = "*";
      rpc-host-whitelist = "${DOMAIN}";
      rpc-host-whitelist-enabled = true;
      rpc-authentication-required = true;
      rpc-password = "${WEB_PASS}";
      rpc-username = "${WEB_USER}";
    };
  };

  environment.etc = {
    # Workaround transmission issue by appending an ipv4 host in /etc/hosts
    hosts.text = ''
      87.98.162.88 portcheck.transmissionbt.com
    '';
    # transmission helper script
    "transmission.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        case $1 in
          up) systemctl restart transmission.service;;
          down) systemctl stop transmission.service;;
          status) systemctl status transmission.service;;
          *) echo "E: Invalid Command"; exit 1;;
        esac
      '';
    };
  };

  # Generate nginx config
  imports = [
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://127.0.0.1:8888/";
      HOST_HEADER = "$host";
    } )
  ];

}