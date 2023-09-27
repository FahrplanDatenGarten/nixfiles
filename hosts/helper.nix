{ lib, config, currentHost ? config.networking.hostName, ... }:
with lib;
rec {
  hosts = {
    martian = {
      meta.intIpv6 = "fd59:974e:6ee8::1";
      services = {
        wireguard = {
          interfaces = {
            "fdg-int" = {
              ips = [ "${hosts.martian.meta.intIpv6}/128" ];
              publicKey = "79NbBslDrdK5fllB4+6wA9mUV7sVQCtAaPsojW0JJ0U=";
              routed = [ "${hosts.martian.meta.intIpv6}/128" ];
              hostname = "martian.infra.fahrplandatengarten.de";
              extraWireguardPeers = [
                { # leona, turingmachine
                  wireguardPeerConfig = {
                    AllowedIPs = [
                      "fd59:974e:6ee8:1000::1/64"
                    ];
                    PublicKey = "XXhmTtGgJskiU03n0VJtBB57d9deND1CND8Pbq8WLHc=";
                  };
                }
                { # leona, enari
                  wireguardPeerConfig = {
                    AllowedIPs = [
                      "fd59:974e:6ee8:1001::1/64"
                    ];
                    PublicKey = "Za6Mq5kTu97ZXfvqQ1zLzxmmNSrtmjD1xSRSzfvH0i0=";
                  };
                }
                { # ember, laptop
                  wireguardPeerConfig = {
                    AllowedIPs = [
                      "fd59:974e:6ee8:1010::1/64"
                    ];
                    PublicKey = "qC9iHtHPf8j+py6eTfFwPMjNp4KXLRiRvaeyqb0pVEo=";
                  };
                }
              ];
            };
          };
        };
      };
    };
    jupiter = {
      meta.intIpv6 = "fd59:974e:6ee8:10::1:1";
      services = {
        wireguard = {
          interfaces = {
            "fdg-int" = {
              ips = [ "${hosts.jupiter.meta.intIpv6}/128" ];
              publicKey = "6gErmrHZ7QoiYfYb2rtD/79tyCmI2WY3fG17KD+cf2Y=";
              routed = [ "${hosts.jupiter.meta.intIpv6}/128" ];
            };
          };
        };
      };
    };
    merkur = {
      meta.intIpv6 = "fd59:974e:6ee8:10::2:1";
      services = {
        wireguard = {
          interfaces = {
            "fdg-int" = {
              ips = [ "${hosts.merkur.meta.intIpv6}/128" ];
              publicKey = "sITj9MPe7BajnhppKgbB8PREal3mUq/rXmHI4MKT+zs=";
              routed = [ "${hosts.merkur.meta.intIpv6}/128" ];
            };
          };
        };
      };
    };
    franzbroetchen = {
      meta.intIpv6 = "fd59:974e:6ee8:10::3:1";
      services = {
        wireguard = {
          interfaces = {
            "fdg-int" = {
              ips = [ "${hosts.franzbroetchen.meta.intIpv6}/128" ];
              publicKey = "uCA6JMXnDKN+7Bk/v8n74/q1p0Dd9V6RWqtPMttMqWo=";
              routed = [ "${hosts.franzbroetchen.meta.intIpv6}/128" ];
              hostname = "franzbroetchen.unix-ag.uni-kl.de";
            };
          };
        };
      };
    };
  };
  groups = {
    wireguard = {
      interfaces = {
        fdg-int = {
          port = 40000;
          routes = [
            { routeConfig.Destination = "fd59:974e:6ee8::/48"; }
          ];
        };
      };
      g_currenthost_generate_peers = ifName:
        (lib.mapAttrsToList (hostname: hostconf:
          let
            ifaceConfig = hostconf.services.wireguard.interfaces.${ifName};
            groupConfig = groups.wireguard.interfaces.${ifName};
          in {
            wireguardPeerConfig = {
              AllowedIPs = [ ifaceConfig.routed ];
              Endpoint = mkIf (ifaceConfig ? hostname)
                "${ifaceConfig.hostname}:${toString groupConfig.port}";
              PublicKey = ifaceConfig.publicKey;
              PersistentKeepalive = 21;
            };
          }) (lib.filterAttrs (hostname: hostconf:
            hostconf.services.wireguard.interfaces.${ifName} ? hostname
            || hosts.${currentHost}.services.wireguard.interfaces.${ifName}
            ? hostname)
            (lib.filterAttrs (hostname: hostconf: hostconf.services.wireguard.interfaces ? ${ifName})
              (lib.filterAttrs (hostname: hostconf: hostname != currentHost) hosts)
            )));

      g_systemd_network_netdevconfig = mapAttrs' (ifName: value:
        let
          ifaceConfig =
            hosts.${currentHost}.services.wireguard.interfaces.${ifName};
        in nameValuePair "30-wg-${ifName}" {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg-${ifName}";
          };
          wireguardConfig = {
            ListenPort = groups.wireguard.interfaces.${ifName}.port;
            PrivateKeyFile =
              config.sops.secrets."hosts/${currentHost}/wireguard_wg-${ifName}_privatekey".path;
          };
          wireguardPeers =
            groups.wireguard.g_currenthost_generate_peers ifName
            ++ (if ifaceConfig ? extraWireguardPeers then
              ifaceConfig.extraWireguardPeers
            else
              [ ]);
        }) hosts.${currentHost}.services.wireguard.interfaces;
      g_systemd_network_networkconfig = mapAttrs' (ifName: value:
        let
          ifaceConfig =
            hosts.${currentHost}.services.wireguard.interfaces.${ifName};
          groupConfig = groups.wireguard.interfaces.${ifName};
        in nameValuePair "30-wg-${ifName}" {
          name = "wg-${ifName}";
          linkConfig = { RequiredForOnline = "yes"; };
          networkConfig = { IPForward = true; };
          address = ifaceConfig.ips;
          routes = if ifaceConfig ? interfaceRoutes then
            ifaceConfig.interfaceRoutes
          else
            groupConfig.routes;
        }) hosts.${currentHost}.services.wireguard.interfaces;
    };
  };
  services = {
    dns-int.g_dns_records = mapAttrs' (hostname: config:
      nameValuePair "${hostname}.wg.infra" { AAAA = [ config.meta.intIpv6 ]; })
      (filterAttrs (h: config: config.meta ? intIpv6) hosts);
    };
}
