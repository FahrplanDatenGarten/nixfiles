{ config, lib, pkgs, ... }:

let
  cfg = config.fdg.app;
  format = pkgs.formats.ini {};
  configFile = format.generate "fdg.cfg" cfg.settings;
  package = pkgs.fahrplandatengarten;
  pythonpath = package.python.pkgs.makePythonPath [ package.propagatedBuildInputs package ];
  dataDir = "/var/lib/fdg";
  configPath = "${dataDir}/.cfg";
in {
  config = lib.mkIf cfg.worker.enable {
    systemd.services."fdg-worker@" = {
      preStart = ''
        ${pkgs.gettext}/bin/envsubst < ${configFile} > ${configPath}
      '';
      serviceConfig = {
        WorkingDirectory = dataDir;
        ExecStart = "${package.dependencyEnv}/bin/celery -A fahrplandatengarten.fahrplandatengarten worker --loglevel INFO --concurrency=10 -n worker%i@%%h";
        StateDirectory = lib.mkIf (dataDir == "/var/lib/fdg") "fdg";
        User = "fdg";
        Group = "fdg";
        PrivateTmp = true;
        Restart = "on-failure";
        TimeoutStartSec = 300;
        EnvironmentFile = cfg.environmentFile;
      };
      environment.FDG_CONFIG_FILE = configPath;
    };
    systemd.targets.fdg-worker = {
      wants = [
        "fdg-worker@1.service"
        "fdg-worker@2.service"
        "fdg-worker@3.service"
        "fdg-worker@4.service"
      ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
