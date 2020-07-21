{ USER, HOME_DIR }:

{

  # Define default non-root user
  users.users.${USER} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
    home = "${HOME_DIR}";
  };

}