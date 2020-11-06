{ SERVICE }:

{

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
        usage() {
        cat <<EOF
        Commands:
          up      | Spin up all containers
          update  | Update all containers
          down    | Shutdown all containers
          restart | Restart all containers
          build   | Build main container
          logs    | Show logs
          sh      | Execute /bin/sh inside main container as root
          bash    | Execute /bin/bash inside main container as root
          help    | Display this help text
        EOF
        }
        case $1 in
          up) $command up -d;;
          update) $command pull; $command up -d --force-recreate;;
          down) $command down;;
          restart) $command restart;;
          build) $command build ${SERVICE};;
          logs) $command logs -f --tail 100;;
          sh) $command exec ${SERVICE} sh;;
          bash) $command exec ${SERVICE} bash;;
          help) usage;;
          *) echo "E: Invalid Command"; echo; usage; exit 1;;
        esac
      '';
    };
  };

}