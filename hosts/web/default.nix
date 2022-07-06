{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../services/dns-knot
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "web";
  networking.domain = "infra.fahrplandatengarten.de";

  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "52:54:00:47:a2:f1";
      linkConfig.Name = "eth0";
    };
    networks."10-eth0" = {
      DHCP = "yes";
      matchConfig = {
        Name = "eth0";
      };
      networkConfig.IPv6PrivacyExtensions = "no";
    };
  };

  system.stateVersion = "22.05";
}


