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
  options.fdg.app = {
    web = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "FahrplanDatenGarten app web / core";
          address = mkOption {
            type = types.str;
            default = "localhost";
          };
          port = mkOption {
            type = types.port;
            default = 8123;
          };
          publicHost = mkOption {
            type = types.str;
            default = "fahrplandatengarten.de";
          };
        };
      };
    };

    worker = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "FahrplanDatenGarten app worker";
        };
      };
    };
    
    environmentFile = mkOption {
      type = types.path;
      description = mdDoc "Environment File to load, for example for secrets";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = format.type;

        options = {
          general = {
            debug = mkOption {
              type = types.bool;
              default = false;
              description = mdDoc ''
                Enable the debug mode, do not use in production.
              '';
            };
            secret_key = mkOption {
              type = types.str;
              description = mdDoc ''
                The secret key, used for example to generate session cookies.
              '';
              default = "$SECRET_KEY";
            };
            static_root = mkOption {
              type = types.str;
              default = "${dataDir}/static";
              description = mdDoc ''
                The directory used to store static files.
              '';
            };
            allowed_hosts = mkOption {
              type = types.str;
              default = "127.0.0.1,::1";
            };
          };
          database = {
            engine = mkOption {
              type = types.str;
              default = "postgresql";
            };
            name = mkOption {
              type = types.str;
              default = "fdg";
            };
            user = mkOption {
              type = types.str;
              default = "fdg";
            };
          };
          celery = {
            result_backend = mkOption {
              type = types.str;
              default = "$CELERY_RESULT_BACKEND_URL";
            };
            broker_url = mkOption {
              type = types.str;
              default = "$CELERY_BROKER_URL";
            };
            task_ignore_result = mkOption {
              type = types.bool;
              default = true;
            };
            task_store_errors_even_if_ignored = mkOption {
              type = types.bool;
              default = true;
            };
          };
          caching = {
            redis_location = mkOption {
              type = types.str;
              default = "$CACHING_REDIS_URL";
            };
          };
          periodic = {
            timetables = mkOption {
              type = types.str;
              default = "*,*/30";
            };
            journeys = mkOption {
              type = types.str;
              default = "*,*/5";
            };
            wagenreihungen = mkOption {
              type = types.str;
              default = "*,*/30";
            };
          };
        };
      };
      default = { };
      description = mdDoc ''
        Configuration for fdg app
      '';
    };
  };

  config = mkIf cfg.web.enable {
    systemd.services.fdg-web = {
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

    users.users."fdg" = {
      isSystemUser = true;
      group = "fdg";
    };
    users.groups."fdg" = { };
  };
}
