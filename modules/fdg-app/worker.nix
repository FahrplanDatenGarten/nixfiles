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
        ExecStart = "${package.dependencyEnv}/bin/celery -A fahrplandatengarten.fahrplandatengarten worker --loglevel INFO --concurrency=${toString cfg.worker.concurrency} -n worker%i@%%h";
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
      wants = map (n: "fdg-worker@${toString n}.service") (lib.range 1 cfg.worker.numWorkers);
      wantedBy = [ "multi-user.target" ];
    };
  };
}
