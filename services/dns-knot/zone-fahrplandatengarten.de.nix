{ dns, config, lib, ... }:

with dns.lib.combinators;

in {
  zone = {
    TTL = 600;
    SOA = ((ttl 600) {
      nameServer = "ns1.fahrplandatengarten.de.";
      adminEmail = "noc@fahrplandatengarten.de";
      serial = 2022070402;
      refresh = 300;
      expire = 604800;
      minimum = 300;
    });

    NS = [
      "ns1.fahrplandatengarten.de"
      "ns2.leona.is"
      "ns3.leona.is"
    ];

    MX = "mail.leona.is";
#    TXT = [
#      helper.mail.spf
#    ];
#    DKIM = [{
#      selector = "mail";
#      p = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxAdCbH2V1TQgnscRit9ogxbPD3tibtgFzdW4EshD737hi7yV3g0njk/8P9UcNx0mqVwjDcBxENL1bd5MywHrRfBrkbaez2wEmZbcGzE5ljaEHk0QzwAvG+Yws4q32EHmLBmwRaT4+wSvXrp6F/FqJ4GDyWigaoEvrc+6tKgc7oAgi4k5VItv/AUJXXHsrWCd81CpcPMzEAbL460ISUmD0xRsIScvEsDCzRPAXi0smkaOxFt5oNQbTZOu22WgkyGuz7y0g/0dX7s/8ZD4J1LiAHJswnF3hq7jIWWAoRmAtKjyEFufghRfAeiZoi+gr1e1MzPKxJ4jJ+l2nA4rNkE+XQIDAQAB";
#    }];
#
#    DMARC = helper.mail.dmarc;
#
#    CAA = helper.caa;

    A = [ "195.39.247.150" ];
    AAAA = [ "2a01:4f8:242:155f:1000::b4d" ];


    subdomains = {
      "web.infra" = "2a01:4f8:242:155f:1000::b4d";

      "ns1".AAAA = "2a01:4f8:242:155f:1000::b4d";

      www.CNAME = [ "web.infra.fahrplandatengarten.de." ];
    };
  };
}
