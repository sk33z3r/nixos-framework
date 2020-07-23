{ config, pkgs, ... }:

{

  # Extra packages
  environment.systemPackages = with pkgs; [
    webhook
  ];

  # Extra aliases
  programs.fish.shellAliases = {
    webhook-service = "/etc/webhook-service.sh";
  };

  # Define cronjobs
  services.cron.systemCronJobs = [
    "00 04 * * *    root    /etc/webhook-service.sh restart"
  ];

  # Define maintenance script
  environment.etc = {
    "webhook-service.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        case $1 in
          start) webhook -hooks /etc/webhooks.json -urlprefix run -port 4004 -verbose -hotreload > /var/www/logs/webhook.log 2>&1 &;;
          stop) pkill webhook;;
          restart)
            pkill webhook
            chown -R root:root /var/www/html
            webhook -hooks /etc/webhooks.json -urlprefix run -port 4004 -verbose -hotreload > /var/www/logs/webhook.log 2>&1 &
          ;;
          status) tail -f /var/www/logs/webhook.log;;
          *) echo "Error: Invalid command, expecting [start|stop|restart|status]"; exit 1;;
        esac
      '';
    };
  };

}