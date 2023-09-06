{ pkgs, lib, config, ... }:

{
  users.users.n0emis = {
    isNormalUser = true;
    hashedPassword =
      "$6$ZvdWexF9y28IrjyW$lxz27/eFjDZWUPY7Lox0aDXO0.TgMBzygZqNSp1HU7itaMI0KbtAOX2H3uZ9hlEo21z.K.JEE.V/b.HpmN.4y1";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcOPtW5FWNIdlMQFoqeyA1vHw+cA8ft8oXSbXPzQNL9 n0emis@n0emis.eu"
    ];
  };
}
