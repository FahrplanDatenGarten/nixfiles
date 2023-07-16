{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../services/dns-knot
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  deployment.targetHost = "128.140.93.148";
  deployment.buildOnTarget = true;

  networking.hostName = "martian";
  networking.domain = "infra.fahrplandatengarten.de";

  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "96:00:02:5e:e1:03";
      linkConfig.Name = "eth0";
    };
    networks."10-eth0" = {
      DHCP = "yes";
      matchConfig = {
        Name = "eth0";
      };
      address = [
        "2a01:4f8:c012:5ab9::1/64"
      ];
      routes = [
        { routeConfig = { Destination = "::/0"; Gateway = "fe80::1"; GatewayOnLink = true; }; }
      ];
    };
  };

  system.stateVersion = "23.11";
}


