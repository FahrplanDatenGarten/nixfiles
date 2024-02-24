{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fdg.app;
  format = pkgs.formats.ini {};
  configFile = format.generate "fdg.cfg" cfg.settings;
  package = pkgs.fahrplandatengarten;
  pythonpath = package.python.pkgs.makePythonPath [ package.propagatedBuildInputs package ];
  dataDir = "/var/lib/fdg";
  configPath = "${dataDir}/.cfg";
in {
  config = mkIf cfg.web.enable {
    systemd.services.fdg-web = {
      path = with pkgs; [ pdftk ];
      environment.PYTHONPATH = pythonpath;
      preStart = ''
        ${pkgs.gettext}/bin/envsubst < ${configFile} > ${configPath}

        ${package}/bin/fdg-manage migrate --no-input
        ${package}/bin/fdg-manage collectstatic --no-input --clear

        chmod -R 755 static
      '';
      serviceConfig = {
        WorkingDirectory = dataDir;
        ExecStart = ''
          ${pkgs.python3Packages.gunicorn}/bin/gunicorn fahrplandatengarten.fahrplandatengarten.wsgi \
            --name fahrplandatengarten \
            --pythonpath ${pythonpath} \
            -b ${cfg.web.address}:${toString cfg.web.port}
          '';
        StateDirectory = lib.mkIf (dataDir == "/var/lib/fdg") "fdg";
        User = "fdg";
        Group = "fdg";
        PrivateTmp = true;
        Restart = "on-failure";
        TimeoutStartSec = 300;
        EnvironmentFile = cfg.environmentFile;
      };
      environment.FDG_CONFIG_FILE = configPath;
      wantedBy = ["multi-user.target"];
    };

    systemd.services.fdg-celerybeat = {
      preStart = ''
        ${pkgs.gettext}/bin/envsubst < ${configFile} > ${configPath}
      '';
      serviceConfig = {
        WorkingDirectory = dataDir;
        ExecStart = "${package.dependencyEnv}/bin/celery -A fahrplandatengarten.fahrplandatengarten beat --loglevel INFO";
        StateDirectory = lib.mkIf (dataDir == "/var/lib/fdg") "fdg";
        User = "fdg";
        Group = "fdg";
        PrivateTmp = true;
        Restart = "on-failure";
        TimeoutStartSec = 300;
        EnvironmentFile = cfg.environmentFile;
      };
      environment.FDG_CONFIG_FILE = configPath;
      wantedBy = ["multi-user.target"];
    };

    networking.firewall.interfaces."wg-fdg-int".allowedTCPPorts = [ 5432 6379 ];
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "fdg" ];
      ensureUsers = [{
        name = "fdg";
        ensurePermissions."DATABASE fdg" = "ALL PRIVILEGES";
      }];
      enableTCPIP = true;
      authentication = ''
        host all all fd59:974e:6ee8::/48 md5
      '';
      settings = {
        max_connections = 1000;
        shared_buffers = "1536MB";
        effective_cache_size = "4608MB";
        maintenance_work_mem = "768MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 500;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "786kB";
        huge_pages = "off";
        min_wal_size = "4GB";
        max_wal_size = "16GB";
      };
    };

    fdg.sops.secrets."services/fdg-app/redis_password" = {
      owner = "redis-fdg";
      group = "telegraf";
      mode = "0440";
    };
    services.redis.servers."fdg" = {
      enable = true;
      requirePassFile = config.sops.secrets."services/fdg-app/redis_password".path;
      port = 6379;
      bind = "fd59:974e:6ee8::1";
    };

    l.telegraf.extraInputs = let
      redis_celery_command = pkgs.writeShellScript "telegraf-redis-celery" ''
        ${pkgs.redis}/bin/redis-cli -a "$(cat ${config.sops.secrets."services/fdg-app/redis_password".path})" -n 0 -h fd59:974e:6ee8::1 -p 6379 llen celery
      '';
    in {
      exec = [{
        commands = [
          redis_celery_command
        ];
        data_format = "value";
        name_suffix = "_redis_celery_length";
      }];
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.web.publicHost}" = {
      enableACME = true;
      forceSSL = true;
      kTLS = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString cfg.web.port}";
      };
      locations."/static/" = {
        root = "/var/lib/fdg";
      };
    };
  };
}
