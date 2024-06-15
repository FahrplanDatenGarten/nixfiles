{ inputs, config, pkgs, lib, ... }:

{
  imports = [
    ../../modules
    inputs.home-manager.nixosModules.home-manager
    inputs.colmena.nixosModules.deploymentOptions
    inputs.sops-nix.nixosModules.sops
    inputs.leona-nixfiles.nixosModules.telegraf
    ../../users/root
    ../../users/ember
    ../../users/leona
    ./nginx.nix
  ];
  nixpkgs.overlays = lib.attrValues inputs.self.overlays;
  deployment.targetHost = lib.mkDefault config.networking.fqdn;
  deployment.targetPort = lib.mkDefault (lib.head config.services.openssh.ports);
  deployment.targetUser = null;
  
  users.mutableUsers = false;
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
    settings = {
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://nix-cache.ember.li"
      ];
      trusted-public-keys = [
        "nix-cache.ember.li-1:smMe5Nc62Ziy2WEC9SKqm0DBH7lCJPmfsDf9c97+9x0="
      ];
    };
  };

  services.journald.extraConfig = "SystemMaxUse=256M";

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PermitRootLogin = lib.mkDefault "no";

  security.sudo.wheelNeedsPassword = lib.mkDefault false;

  time.timeZone = "Europe/Berlin";

  environment.variables.EDITOR = "hx";
  programs.zsh.enable = true;

  networking.useNetworkd = true;
  networking.nftables.enable = true;
  networking.useDHCP = false;
  services.resolved.dnssec = "false"; # broken :(
  services.resolved.extraConfig = ''
    FallbackDNS=
    Cache=no-negative
  '';

  environment.systemPackages = with pkgs; [
    bat
    bottom
    bind.dnsutils # for dig
    file
    eza
    git
    htop
    mtr
    neovim
    helix
    nmap
    openssl
    ripgrep
    rsync
    tmux
    wget
    wireguard-tools
  ];
}
