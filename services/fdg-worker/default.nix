{ config, ... }: {
  fdg.sops.secrets."services/fdg-app/env".owner = "root";
  fdg.app = {
    worker = {
      enable = true;
    };
    settings.database = {
      host = "martian.wg.infra.fahrplandatengarten.de";
      password = "$DB_PASSWORD";
    };
    environmentFile = config.sops.secrets."services/fdg-app/env".path;
  };
}
