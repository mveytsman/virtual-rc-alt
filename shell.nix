with (import <nixpkgs> { });
let
  inherit (lib) optional;

  basePackages =
    [ git libxml2 openssl zlib curl libiconv docker-compose postgresql_12 ]
    ++ optional stdenv.isLinux inotify-tools;

  elixirPackages = [ elixir_1_10 ];

  nodePackages = [ nodejs yarn ];

  inputs = basePackages ++ elixirPackages ++ nodePackages;

  localPath = ./. + "/local.nix";

  final = if builtins.pathExists localPath then
    inputs ++ (import localPath)
  else
    inputs;

  # define shell startup command with special handling for OSX
  baseHooks = ''
    export PS1='\n\[\033[1;32m\][nix-shell:\w]($(git rev-parse --abbrev-ref HEAD))\$\[\033[0m\] '
    export LANG=en_US.UTF-8
    set -a
    set +a
  '';

  elixirHooks = ''
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
    export ERL_AFLAGS="-kernel shell_history enabled"
  '';

  nodeHooks = ''
    export NODE_BIN=$PWD/assets/node_modules/.bin
    export PATH=$NODE_BIN:$PATH
  '';

  hooks = baseHooks + elixirHooks + nodeHooks; 
in mkShell {
  buildInputs = final;
  shellHook = hooks;
}
