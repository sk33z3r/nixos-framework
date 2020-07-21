{ config, pkgs, ... }:

let

  SERVICE = "minecraft";
  DATA_DIR = "/data/${SERVICE}";
  IP4 = "20";

in

{

  # Filesystem setup
  system.activationScripts.minecraft = {
    text = ''
      mkdir -p ${DATA_DIR}
      mkdir -p ${DATA_DIR}-forge/mods
      mkdir -p ${DATA_DIR}-fabric/mods
    '';
    deps = [];
  };

  # Extra aliases
  programs.fish.shellAliases = {
    "${SERVICE}" = "/etc/${SERVICE}.sh";
  };

  # Configs and scripts
  environment.etc = {
    "${SERVICE}.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        case $2 in
          fabric)
            echo "Setting VERSION to FABRIC"
            compose="/etc/${SERVICE}-fabric.compose"
          ;;
          forge)
            echo "Setting VERSION to FORGE"
            compose="/etc/${SERVICE}-forge.compose"
          ;;
          *)
            echo "Setting VERSION to VANILLA"
            compose="/etc/${SERVICE}.compose"
          ;;
        esac
        command="docker-compose -f $compose -p ${SERVICE}"
        case $1 in
          up) $command up -d --force-recreate;;
          update) $command pull; $command up -d --force-recreate;;
          down) $command down;;
          logs) $command logs -f --tail 100;;
          *) echo "E: Invalid Command"; exit 1;;
        esac
      '';
    };
    "${SERVICE}.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: itzg/minecraft-server
            container_name: ${SERVICE}
            environment:
              EULA: "TRUE"
              TZ: "America/New_York"
              ENABLE_AUTOPAUSE: "TRUE"
              OVERRIDE_SERVER_PROPERTIES: "true"
              SERVER_NAME: "Vanilla"
              DIFFICULTY: "hard"
              WHITELIST: "Celestro,mddawley,reverbtank"
              OPS: "Celestro"
              ICON: "https://blackrookllc.com/images/favicon.ico"
              MAX_PLAYERS: "5"
              ALLOW_NETHER: "true"
              ANNOUNCE_PLAYER_ACHIEVEMENTS: "false"
              ENABLE_COMMAND_BLOCK: "false"
              FORCE_GAMEMODE: "true"
              GENERATE_STRUCTURES: "true"
              SNOOPER_ENABLED: "false"
              SPAWN_ANIMALS: "true"
              SPAWN_MONSTERS: "true"
              SPAWN_NPCS: "true"
              SPAWN_PROTECTION: "0"
              SEED: "downwithbrowntown"
              MOTD: "Just plain ol' vanilla."
              PVP: "true"
              LEVEL_TYPE: "Floating Islands"
              LEVEL: "BrownTown"
              ALLOW_FLIGHT: "true"
              ONLINE_MODE: "true"
              MAX_MEMORY: "4G"
              GUI: "FALSE"
              TYPE: "VANILLA"
              VERSION: "SNAPSHOT"
            volumes:
              - ${DATA_DIR}:/data
            restart: always
            ports:
              - "1337:25565"
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
        networks:
          blackrook:
            name: blackrook
            ipam:
              config:
                - subnet: 172.100.0.0/24
      '';
    };
    "${SERVICE}-forge.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: itzg/minecraft-server
            container_name: ${SERVICE}
            environment:
              EULA: "TRUE"
              TZ: "America/New_York"
              ENABLE_AUTOPAUSE: "TRUE"
              OVERRIDE_SERVER_PROPERTIES: "true"
              SERVER_NAME: "Forge!"
              DIFFICULTY: "hard"
              WHITELIST: "Celestro,mddawley,reverbtank"
              OPS: "Celestro"
              ICON: "https://blackrookllc.com/images/favicon.ico"
              MAX_PLAYERS: "5"
              ALLOW_NETHER: "true"
              ANNOUNCE_PLAYER_ACHIEVEMENTS: "false"
              ENABLE_COMMAND_BLOCK: "false"
              FORCE_GAMEMODE: "true"
              GENERATE_STRUCTURES: "true"
              SNOOPER_ENABLED: "false"
              SPAWN_ANIMALS: "true"
              SPAWN_MONSTERS: "true"
              SPAWN_NPCS: "true"
              SPAWN_PROTECTION: "0"
              SEED: "downwithbrowntown"
              MOTD: "Who knows what kind of tech lies beyond..."
              PVP: "true"
              LEVEL_TYPE: "DEFAULT"
              LEVEL: "BrownTown"
              ALLOW_FLIGHT: "true"
              ONLINE_MODE: "true"
              MAX_MEMORY: "4G"
              GUI: "FALSE"
              TYPE: "FORGE"
              FORGEVERSION: "14.23.5.2838"
              VERSION: "1.12.2"
            volumes:
              - ${DATA_DIR}-forge:/data
            restart: always
            ports:
              - "1337:25565"
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
        networks:
          blackrook:
            name: blackrook
            ipam:
              config:
                - subnet: 172.100.0.0/24
      '';
    };
    "${SERVICE}-fabric.compose" = {
      text = ''
        version: '3.7'
        services:
          ${SERVICE}:
            image: itzg/minecraft-server
            container_name: ${SERVICE}
            environment:
              EULA: "TRUE"
              TZ: "America/New_York"
              ENABLE_AUTOPAUSE: "TRUE"
              OVERRIDE_SERVER_PROPERTIES: "true"
              SERVER_NAME: "Fabric!"
              DIFFICULTY: "hard"
              WHITELIST: "Celestro,mddawley,reverbtank"
              OPS: "Celestro"
              ICON: "https://blackrookllc.com/images/favicon.ico"
              MAX_PLAYERS: "5"
              ALLOW_NETHER: "true"
              ANNOUNCE_PLAYER_ACHIEVEMENTS: "false"
              ENABLE_COMMAND_BLOCK: "false"
              FORCE_GAMEMODE: "true"
              GENERATE_STRUCTURES: "true"
              SNOOPER_ENABLED: "false"
              SPAWN_ANIMALS: "true"
              SPAWN_MONSTERS: "true"
              SPAWN_NPCS: "true"
              SPAWN_PROTECTION: "0"
              SEED: "downwithbrowntown"
              MOTD: "The new and improved experience!"
              PVP: "true"
              LEVEL_TYPE: "DEFAULT"
              LEVEL: "BrownTown"
              ALLOW_FLIGHT: "true"
              ONLINE_MODE: "true"
              MAX_MEMORY: "4G"
              GUI: "FALSE"
              TYPE: "FABRIC"
              VERSION: "SNAPSHOT"
            volumes:
              - ${DATA_DIR}-fabric:/data
            restart: always
            ports:
              - "1337:25565"
            networks:
              blackrook:
                ipv4_address: 172.100.0.${IP4}
        networks:
          blackrook:
            name: blackrook
            ipam:
              config:
                - subnet: 172.100.0.0/24
      '';
    };
  };

}