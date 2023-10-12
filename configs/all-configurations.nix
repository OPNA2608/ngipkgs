{
  # LiberaForms is intentionally disabled.
  # Refer to <https://github.com/ngi-nix/ngipkgs/issues/40>.
  #liberaforms-container = import ./liberaforms/container.nix;
  flarum = {
    imports = [./flarum];
  };
  pretalx-postgresql = {
    imports = [
      ./pretalx/pretalx.nix
      ./pretalx/postgresql.nix
      ./dummy.nix
    ];
  };
  pretalx-mysql = {
    imports = [
      ./pretalx/pretalx.nix
      ./pretalx/mysql.nix
      ./dummy.nix
    ];
  };
  kbin = {
    imports = [
      ./kbin
      ./dummy.nix
    ];
  };
}
