{ config, ... }: {
  fdg.sops.secrets."services/fdg-app/env".owner = "root";
  fdg.app = {
    worker = {
      enable = true;
    };
    settings = {
      database = {
        host = "martian.wg.infra.fahrplandatengarten.de";
        password = "$DB_PASSWORD";
      };
      "ris.stations" = {
        url = "$RIS_STATIONS_URL";
        client_id = "$RIS_STATIONS_ID";
        api_key = "$RIS_STATIONS_KEY";
      };
    };
    environmentFile = config.sops.secrets."services/fdg-app/env".path;
  };
}
