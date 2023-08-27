{ inputs, pkgs, config, lib, ... }:
let
  dns = inputs.dns;
  dnsutil = dns.util.${pkgs.stdenv.hostPlatform.system};
  hosthelper = import ../../hosts/helper.nix { inherit lib config; };
in {
  fdg.sops.secrets."services/dns-knot/keys".owner = "knot";
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  services.knot = {
    enable = true;
#        listen: 195.39.247.146@53
    keyFiles = [
      config.sops.secrets."services/dns-knot/keys".path
    ];
    extraConfig = ''
      server:
        listen: 127.0.0.11@53
        listen: 128.140.93.148@53
        listen: 2a01:4f8:c012:5ab9::1@53
      remote:
        - id: leona_ns2
          address: 2001:470:1f0b:1112::1
          key: fdg_leona_secondary
        - id: leona_ns3
          address: 2a03:4000:f:85f::1
          key: fdg_leona_secondary
      acl:
        - id: leona_secondary_transfer
          address: [2001:470:1f0a:1111::2/64, 2001:470:1f0b:1112::1/128, 2a03:4000:f:85f::1/128]
          key: fdg_leona_secondary
          action: transfer
        - id: internal
          address: [127.0.0.0/8]
          action: transfer
      mod-rrl:
        - id: default
          rate-limit: 200   # Allow 200 resp/s for each flow
          slip: 2           # Every other response slips
      policy:
        - id: ecdsa256
          algorithm: ecdsap256sha256
          ksk-size: 256
          zsk-size: 256
          zsk-lifetime: 90d
          nsec3: on
      template:
        - id: default
          semantic-checks: on
          global-module: mod-rrl/default
        - id: signedprimary
          dnssec-signing: on
          dnssec-policy: ecdsa256
          semantic-checks: on
          notify: [leona_ns2, leona_ns3]
          acl: [leona_secondary_transfer, internal]
          zonefile-sync: -1
          zonefile-load: difference
          journal-content: changes
      zone:
        - domain: fahrplandatengarten.de
          file: "${dnsutil.writeZone "fahrplandatengarten.de" (import ./zone-fahrplandatengarten.de.nix { inherit hosthelper lib dns config; }).zone}"
          template: signedprimary
    '';
  };
}
