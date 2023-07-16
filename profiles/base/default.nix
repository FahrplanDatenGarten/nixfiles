{ inputs, config, pkgs, lib, ... }:

{
  imports = [
    ../../modules
    inputs.home-manager.nixosModules.home-manager
    inputs.colmena.nixosModules.deploymentOptions
    inputs.sops-nix.nixosModules.sops
    ../../users/root
    ../../users/n0emis
    ../../users/leona
#    ./nginx.nix
  ];
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
    settings.trusted-users = [ "root" "@wheel" ];
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };

  services.journald.extraConfig = "SystemMaxUse=256M";

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.kbdInteractiveAuthentication = false;
  services.openssh.permitRootLogin = lib.mkDefault "no";

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
    bind.dnsutils # for dig
    file
    exa
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
  ];
}
