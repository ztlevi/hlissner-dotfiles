# modules/shell/zsh.nix --- ...

{ config, options, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.shell.zsh;
in {
  options.modules.shell.zsh = with types; {
    enable = mkBoolOpt false;

    aliases = mkOpt (attrsOf (either str path)) { };

    rcInit = mkOpt' lines "" ''
      Zsh lines to be written to $XDG_CONFIG_HOME/zsh/extra.zshrc and sourced by
      $XDG_CONFIG_HOME/zsh/.zshrc
    '';
    envInit = mkOpt' lines "" ''
      Zsh lines to be written to $XDG_CONFIG_HOME/zsh/extra.zshenv and sourced
      by $XDG_CONFIG_HOME/zsh/.zshenv
    '';

    rcFiles = mkOpt (listOf (either str path)) [ ];
    envFiles = mkOpt (listOf (either str path)) [ ];
  };

  config = mkIf cfg.enable {
    users.defaultUserShell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      # I init completion myself, because enableGlobalCompInit initializes it too
      # soon, which means commands initialized later in my config won't get
      # completion, and running compinit twice is slow.
      enableGlobalCompInit = false;
      promptInit = "";
    };

    user.packages = with pkgs; [
      zsh
      htop
      starship
      tldr
      tree
      fasd
      fd
      direnv
      exa
      bat
      du-dust
      ripgrep
      procs
      shellcheck
      shfmt
      trash-cli
      neofetch
      jq
      bandwhich
      eva
    ];

    env.ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    env.ZSH_CACHE_DIR = "$XDG_CACHE_HOME/zsh";

    modules.shell.zsh.rcFiles =
      [ "${config.dotfiles.configDir}/shell/zsh/rc.zsh" ];

    home.file = {
      ".p10k.zsh".source = "${config.dotfiles.configDir}/shell/zsh/.p10k.zsh";
    };
    # Write it recursively so other modules can write files to it
    home.configFile = {
      "zsh" = {
        source = "${config.dotfiles.configDir}/shell/zsh";
        recursive = true;
      };
      "starship.toml" = {
        source = "${config.dotfiles.configDir}/shell/zsh/config/starship.toml";
      };
      "ripgreprc" = {
        source = "${config.dotfiles.configDir}/shell/zsh/config/ripgreprc";
      };

      # Why am I creating extra.zsh{rc,env} when I could be using extraInit?
      # Because extraInit generates those files in /etc/profile, and mine just
      # write the files to ~/.config/zsh; where it's easier to edit and tweak
      # them in case of issues or when experimenting.
      "zsh/extra.zshrc".text = let
        aliasLines = mapAttrsToList (n: v: ''alias ${n}="${v}"'') cfg.aliases;
      in ''
        # This file was autogenerated, do not edit it!
        ${concatStringsSep "\n" aliasLines}
        ${concatMapStrings (path: ''
          source '${path}'
        '') cfg.rcFiles}
        ${cfg.rcInit}
      '';

      "zsh/extra.zshenv".text = ''
        # This file is autogenerated, do not edit it!
        ${concatMapStrings (path: ''
          source '${path}'
        '') cfg.envFiles}
        ${cfg.envInit}
      '';
    };
    system.userActivationScripts.zshCleanupInitCache = ''
      rm -rf $HOME/.cache/zsh
      rm -f $HOME/.config/zsh/*.zwc
      rm -f $HOME/.config/zsh/.zshrc.zwc
      rm -f $HOME/.config/zsh/.zshenv.zwc

      rm -rf ~/.zinit/snippets/*.config--*--config--shell--zsh
    '';

    system.userActivationScripts.zshInitTerminfo = ''
      ${pkgs.ncurses}/bin/tic -x -o ~/.terminfo ${config.dotfiles.configDir}/shell/zsh/xterm-24bit.terminfo
    '';
  };
}
