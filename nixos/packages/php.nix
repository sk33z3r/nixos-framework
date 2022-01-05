{ config, ... }:

{

  services.phpfpm.pools.mypool = {
    user = "phpuser";
    settings = {
      pm = "dynamic";
      "listen.owner" = config.services.nginx.user;
      "pm.max_children" = 5;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 3;
      "pm.max_requests" = 500;
    };
  };

  users.users.phpuser = {
    isSystemUser = true;
    createHome = false;
    group  = "phpuser";
  };
  users.groups.phpuser = {};

}