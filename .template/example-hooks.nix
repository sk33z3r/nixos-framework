{ config, pkgs, ... }:

{

  # Define webhooks
  environment.etc = {
    "webhooks.json" = {
      text = ''
        [
          {
            "id": "hook01",
            "execute-command": "git",
            "pass-arguments-to-command": [ { "source": "string", "name": "pull" } ],
            "command-working-directory": "/var/www/html/example.tld"
          },
          {
            "id": "hook02",
            "execute-command": "git",
            "pass-arguments-to-command": [ { "source": "string", "name": "pull" } ],
            "command-working-directory": "/var/www/html/client01.com"
          }
        ]
      '';
    };
  };

}