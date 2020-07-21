{ DOMAIN, USER, GROUP, HOME_DIR, SYNC_DIR }:

{

  # Define syncthing service
  services.syncthing = {
    enable = true;
    systemService = true;
    dataDir = "${SYNC_DIR}";
    configDir = "${HOME_DIR}/.config/syncthing";
    user = "${USER}";
    group = "${GROUP}";
  };

  # Generate nginx config
  imports = [
    ( import ../nginx/proxy.nix {
      DOMAIN = "${DOMAIN}";
      DEST = "http://127.0.0.1:8384/";
      HOST_HEADER = "localhost";
    } )
  ];

}