{ SERVICE }:

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p /build
    '';
    deps = [];
  };

  # Script alias
  programs.fish.shellAliases = {
    "${SERVICE}" = "/etc/${SERVICE}.sh";
  };

  # Maintenance script template
  environment.etc = {
    "${SERVICE}.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        compose="/etc/${SERVICE}.compose"
        command="docker-compose -f $compose -p ${SERVICE}"
        case $1 in
          up) $command up -d;;
          update) $command pull; $command up -d --force-recreate;;
          down) $command down;;
          restart) $command restart;;
          build) $command build ${SERVICE};;
          logs) $command logs -f --tail 100;;
          *) echo "E: Invalid Command"; exit 1;;
        esac
      '';
    };
  };

}