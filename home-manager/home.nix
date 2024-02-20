{ config, pkgs, pkgs-unstable, ... }:

{
  # manage.
  home.username = "benjamin";
  home.homeDirectory = "/home/benjamin";

  programs.git = {
    enable = true;
    userName = "benbrastmckie";
    userEmail = "benbrastmckie@gmail.com";
  };

  home.stateVersion = "23.11"; # Please read the comment before changing.

  # # home.packages allows you to install Nix packages into your environment.
  # home.packages = 
  #   (with pkgs; [
  #     (python311.withPackages(p: with p; [
  #       z3 
  #       setuptools 
  #       # pynvim 
  #       # pylint 
  #       # black  
  #       # isort  
  #     ]))
  #     (nerdfonts.override { fonts = [ "RobotoMono" ]; })
  #     kitty
  #     vivaldi
  #     neovim
  #     neovim-remote
  #     zathura
  #     zotero
  #     fish
  #     wget
  #     gnome3.gnome-tweaks
  #     oh-my-fish
  #     git
  #     python3
  #     slides
  #     zoxide
  #     plots
  #     gnomeExtensions.unite
  #     lazygit
  #     fzf
  #     ripgrep
  #     pandoc
  #     nodejs_20
  #     xsel
  #     texlive.combined.scheme-full
  #     libsForQt5.okular
  #     gcc
  #     unzip
  #     tree-sitter
  #     perl
  #     gnumake
  #     fd
  #     xdotool
  #     pstree
  #     nix-index
  #     home-manager
  #     zoom-us
  #     vlc
  #     lua-language-server
  #     stylua
  #     hello
  #   ])
  #
  #   ++
  #
  #   (with pkgs-unstable; [
  #     pdfannots
  #   ]);



  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/fish/config.fish".source = dotfiles/config.fish;
    ".config/kitty/kitty.conf".source = dotfiles/kitty.conf;
    ".config/zathura/zathurarc".source = dotfiles/zathurarc;
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
