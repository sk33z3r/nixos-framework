{ config, lib, pkgs, ... }:

{

  services.phpfpm.pools.phpuser = {
    user = "phpuser";
    settings = {
      "listen.owner" = "root";
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
    phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
  };

  users.users.phpuser = {
    isSystemUser = true;
    createHome = true;
    home = "/var/www/html";
    group  = "phpuser";
  };
  users.groups.phpgroup = {};

}