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
  imports = [
    ./web.nix
    ./worker.nix
  ];

  options.fdg.app = {
    web =  {
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

    worker = {
      enable = mkEnableOption "FahrplanDatenGarten app worker";
      concurrency = mkOption {
        type = types.int;
        default = 7;
      };
      numWorkers = mkOption {
        type = types.int;
        default = 4;
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
            host = mkOption {
              type = types.str;
              default = "";
            };
            password = mkOption {
              type = types.str;
              default = "";
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

  config = mkIf (cfg.web.enable || cfg.worker.enable) {
    users.users."fdg" = {
      isSystemUser = true;
      group = "fdg";
    };
    users.groups."fdg" = { };
  };
}
