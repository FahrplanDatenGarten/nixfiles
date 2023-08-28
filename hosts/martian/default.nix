{ config, lib, pkgs, ... }:

let 
  hosthelper = import ../helper.nix { inherit lib config; };
in {
  imports = [
    ./hardware-configuration.nix
    ../../services/dns-knot
    ../../services/fdg-web
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  deployment.buildOnTarget = true;

  networking.hostName = "martian";
  networking.domain = "infra.fahrplandatengarten.de";

  networking.firewall.allowedUDPPorts = [ 40000 ];
  fdg.sops.secrets."hosts/martian/wireguard_wg-fdg-int_privatekey".owner = "systemd-network";
  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "96:00:02:5e:e1:03";
      linkConfig.Name = "eth0";
    };
    netdevs = hosthelper.groups.wireguard.g_systemd_network_netdevconfig;
    networks = {
      "10-eth0" = {
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
    } // hosthelper.groups.wireguard.g_systemd_network_networkconfig;
  };

  system.stateVersion = "23.11";
}


