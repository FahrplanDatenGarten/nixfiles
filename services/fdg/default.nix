{ config, pkgs, ...}:
let
  package = pkgs.fahrplandatengarten;
  configFile = ''
    [general]
    debug = False
    secret_key = $SECRET_KEY
    static_root = /var/www/static
    allowed_hosts = mars.het.nue.de.fahrplandatengarten.de,fahrplandatengarten.de,www.fahrplandatengarten.de,127.0.0.1,::1

    [database]
    engine = postgresql
    host = mars.het.nue.de.vpn.fahrplandatengarten.de
    name = fdg
    user = fdg

    [celery]
    result_backend = redis://:$REDIS_PASSWORD@mars.het.nue.de.vpn.fahrplandatengarten.de:6379/0
    broker_url = redis://:$REDIS_PASSWORD@mars.het.nue.de.vpn.fahrplandatengarten.de:6379/0
    task_ignore_result = true
    task_store_errors_even_if_ignored = true

    [caching]
    redis_location = redis://:$REDIS_PASSWORD@mars.het.nue.de.vpn.fahrplandatengarten.de:6379/1

    [periodic]
    timetables = *,*/30
    journeys = *,*/5
    wagenreihungen = *,*/30

  '';
  pythonpath = "${package.python.pkgs.makePythonPath [ package.propagatedBuildInputs package ]}";
in {
  systemd.services.f = {
    environment.PYTHONPATH = pythonpath;
    preStart = ''
      ${package}/bin/fdg-manage migrate --no-input
      ${package}/bin/fdg-manage collectstatic --no-input --clear
    '';
    serviceConfig = {
      WorkingDirectory = "/var/lib/fahrplandatengarten";
      ExecStart = ''
        ${pkgs.python310Packages.gunicorn}/bn/gunicorn fahrplandatengarten.fahrplandatengarten.wsgi \
          --name fahrplandatengarten \
          --pythonpath ${pythonpath} \
      '';
    };
  };
}
