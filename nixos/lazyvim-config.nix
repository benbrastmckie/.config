{ pkgs, ... }:

pkgs.neovim.override {
  config = {
    # Replace '/path/to/your/neovim/config' with the actual path to your NeoVim configuration directory
    customRC = ''
      set runtimepath+=/home/benjamin/.config/lazyvim/
      source /home/benjamin/.config/lazyvim/init.lua
    '';
  };
}
