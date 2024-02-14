# So far this isn't doing anything; couldn't install with: nix-env -iA default_env
# ~/.config/nixpkgs/overlays/default_env.nix
self: super: {
  myEnv = super.buildEnv {
    name = "default_env";
    paths = [
      # A Python 3 interpreter with some packages
      (self.python3.withPackages (
        ps: with ps; [
          # pyflakes
          # pytest
          # python-language-server
          z3
          setuptools
        ]
      ))

      # Some other packages we'd like as part of this env
      self.mypy
      self.black
      self.tmux
      self.pip
      self.pynvim
      self.pylint
      self.black
      self.isort
    ];
  };
}
