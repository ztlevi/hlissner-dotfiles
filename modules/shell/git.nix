{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.git;
in {
  options.modules.shell.git = {
    enable = mkBoolOpt false;
    # TODO: move gpg sign here
    enableGpgSign = mkBoolOpt true;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      git-lfs
      gitAndTools.gh
      gitAndTools.diff-so-fancy
      (mkIf config.modules.shell.gnupg.enable gitAndTools.git-crypt)
    ];
    home.configFile = {
      "git/config".source = "${config.dotfiles.configDirBackupDir}/git/config";
      "git/ignore".source = "${config.dotfiles.configDirBackupDir}/git/ignore";
    };
    modules.shell.zsh.rcFiles = [ "${config.dotfiles.configDirBackupDir}/git/aliases.zsh" ];
  };
}
