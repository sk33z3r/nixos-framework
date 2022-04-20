# NixOS Config Framework

This repo is intended to be included as a submodule in other repositories as a library.

## Example Template Usage

For templated derivations, you can import them in a machine's config and pass variables like this:

```nix
imports = [
    ( import ./framework/nixos/syncthing.nix {
        DOMAIN = "example.tld";
        USER = "username";
        GROUP = "users";
        HOME_DIR = "/home/username";
        SYNC_DIR = "/home/username/sync";
    } )
];
```

Look at the first line of any `.nix` file for list of variables needed to build it.

# New Client Template

## Initial Setup

Copy the `.template` directory and initialize as a new git repo with a submodule, like so:

```shell
$ cp -r ./.template /my/git/repos/clientname
$ cd /my/git/repos/clientname
$ git init
$ git submodule add https://git.blackrookllc.com/black-rook-llc/nixos-framework.git framework
$ git submodule update --init
```

Now you should be able to follow `example.nix` to build machines. Keep in mind it's not an exhaustive example of every derivation that might exist in the repo. Best to check the first line of any `.nix` module you want to add for exactly which arguments you need to pass.

Once you've got your configs together and pulled to the machine and the default config built at least once (generating any `hardware.nix` files), run `./git.sh --link example.nix` to setup your new configuration. This only needs to be done once and symlinks `example.nix` in the local repository to `/etc/nixos/configuration.nix`, and backs up the old as `configuration.nix.bak`.

## Git Helper

```shell
Usage: ./git.sh [argument]

                        | no argument runs git pull
  -s, --switch          | pulls from git, switches config
  -u, --upgrade         | pulls from git, forces package upgrades while switching
  -f, --framework       | pulls and commits the latest framework from master
  -l, --link [name.nix] | links the configuration.nix file
  -h, --help            | this help message
```

## Updating the framework

Any time there is a new framework release, you can update it with the below command. This simply updates the submodule properly, then commits only that update to your repo.

```shell
$ ./git.sh --framework
```