{ config, pkgs, ... }:

{

  services = {
    openvpn.servers = {
      netherlands = {
        autoStart = false;
        updateResolvConf = true;
        config = ''
          config /root/.mullvad/netherlands.conf
        '';
      };
    };
  };

}