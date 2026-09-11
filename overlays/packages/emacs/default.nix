_self: super: {
  emacs = (super.emacsPackagesFor super.emacs).emacsWithPackages (epkgs: [
    epkgs.vterm
    epkgs.straight
  ]);
}
