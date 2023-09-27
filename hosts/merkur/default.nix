{ config, lib, pkgs, ... }:

let
  hosthelper = import ../helper.nix { inherit lib config; };
in {
  imports = [
    ./hardware-configuration.nix
    ../../services/fdg-worker
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  deployment.buildOnTarget = true;

  l.telegraf = {
    enable = true;
    allowedNet = "fd59:974e:6ee8::/48";
    host = "[fd59:974e:6ee8:10::2:1]";
    diskioDisks = [ "sda" ];
  };

  networking.hostName = "merkur";
  networking.domain = "wg.infra.fahrplandatengarten.de";

  networking.firewall.allowedUDPPorts = [ 40000 ];
  fdg.sops.secrets."hosts/merkur/wireguard_wg-fdg-int_privatekey".owner = "systemd-network";
  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "52:54:00:7b:38:e6";
      linkConfig.Name = "eth0";
    };
    netdevs = hosthelper.groups.wireguard.g_systemd_network_netdevconfig;
    networks = {
      "10-eth0" = {
        matchConfig = {
          Name = "eth0";
        };
        gateway = [ "10.152.28.1" ];
        address = [ "10.152.28.4/26" ];
        dns = [ "9.9.9.9" ];
      };
    } // hosthelper.groups.wireguard.g_systemd_network_networkconfig;
  };

  system.stateVersion = "23.11";
}
