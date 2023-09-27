{ config, lib, pkgs, ... }:

let
  hosthelper = import ../helper.nix { inherit lib config; };
in {
  imports = [
    ./hardware-configuration.nix
    ../../services/fdg-worker
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  deployment.buildOnTarget = true;

  l.telegraf = {
    enable = true;
    allowedNet = "fd59:974e:6ee8::/48";
    host = "[fd59:974e:6ee8:10::3:1]";
    diskioDisks = [ "sda" ];
  };

  networking.hostName = "franzbroetchen";
  networking.domain = "unix-ag.uni-kl.de";

  networking.firewall.allowedUDPPorts = [ 40000 ];
  fdg.sops.secrets."hosts/franzbroetchen/wireguard_wg-fdg-int_privatekey".owner = "systemd-network";
  systemd.network = {
    links."10-eth0" = {
      matchConfig.MACAddress = "7e:11:21:e9:46:72";
      linkConfig.Name = "eth0";
    };
    netdevs = hosthelper.groups.wireguard.g_systemd_network_netdevconfig;
    networks = {
      "10-eth0" = {
        DHCP = "yes";
        matchConfig = {
          Name = "eth0";
        };
      };
    } // hosthelper.groups.wireguard.g_systemd_network_networkconfig;
  };

  system.stateVersion = "23.11";
}
