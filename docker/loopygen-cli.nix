{ DOMAIN }:

let

  SERVICE = "loopygen";
  IP4 = "6";
  COLLECTIONS_DIR = "/data/${SERVICE}";

in

{

  # Filesystem setup
  system.activationScripts."${SERVICE}" = {
    text = ''
      mkdir -p ${DATA_DIR}
    '';
    deps = [];
  };

  # Extra aliases
  programs.fish.shellAliases = {
    loopygen-cli = "/etc/loopygen-cli.sh";
  };

  # /etc files
  environment.etc = {
    "loopygen-cli.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash

        name="loopygen-cli"
        tag="sk33z3r/$name"

        update() {
            docker pull $tag
        }

        usage() {
        cat <<EOF

            LooPyGen CLI Utility Script

            Usage: $0 [command]

            Commands:
            update                | Pull the latest image
            secrets               | Force remove the secrets Docker volume
            {command}             | Run a command inside the container

        EOF
        }

        case $1 in
            update) update;;
            secrets) docker volume rm -f $name;;
            -h|-help|help) usage;;
            cid) # only mount local directory and set a new workdir inside the container
                docker run -it --rm --name $name \
                    -w /scan \
                    -v $PWD:/scan \
                    $tag "$@"
            ;;
            *) # run a command inside a self-destructing container
                docker run -it --rm --name $name \
                    -v $name:/loopygen/.secrets \
                    -v $PWD/collections:/loopygen/collections:rw \
                    $tag "$@"
            ;;
        esac
      '';
    };
  };

}