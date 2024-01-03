{ pkgs, ... }:

pkgs.neovim.override {
  config = {
    # Replace '/path/to/your/neovim/config' with the actual path to your NeoVim configuration directory
    customRC = ''
      set runtimepath+=/home/benjamin/.config/nvim/
      source /home/benjamin/.config/nvim/init.lua
    '';
  };
}
