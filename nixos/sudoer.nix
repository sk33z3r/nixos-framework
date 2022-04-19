{ USER, HOME_DIR, UID }:

{

  # Define default non-root user
  users.users.${USER} = {
    isNormalUser = true;
    uid = UID;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    home = "${HOME_DIR}";
  };

}