{ USER, HOME_DIR, UID }:

{

  # Define default non-root user
  users.users.${USER} = {
    isNormalUser = true;
    uid = UID;
    extraGroups = [ "docker" ];
    home = "${HOME_DIR}";
  };

}