{ config, ... }: {
  fdg.sops.secrets."services/fdg-app/env".owner = "root";
  fdg.app = {
    web = {
      enable = true;
    };
    environmentFile = config.sops.secrets."services/fdg-app/env".path;
    settings = {
      general.allowed_hosts = "fahrplandatengarten.de,127.0.0.1,::1";
    };
  };
}
