{ pkgs, lib, config, ... }:

{
  users.users.n0emis = {
    isNormalUser = true;
    hashedPassword =
      "$6$ZvdWexF9y28IrjyW$lxz27/eFjDZWUPY7Lox0aDXO0.TgMBzygZqNSp1HU7itaMI0KbtAOX2H3uZ9hlEo21z.K.JEE.V/b.HpmN.4y1";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcOPtW5FWNIdlMQFoqeyA1vHw+cA8ft8oXSbXPzQNL9 n0emis@n0emis.eu"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8xqVakxJ+AwcIrS/wyL03N++pE09epwMFlIMXWvlpwwEp1J/0H7nygwxk/9LIZdabs/ETWn0s8oHAkc7YR1c6ajSTCDiZEYATAWt7t8t4Gw/80c8u8T50lIqmiDEEVbOVv3Vta/pAN4hAUp9U5DpYCkQbvF+NKKcK3Yp8d9usNC6ohqgTK+IGAEdMhvpbbNppDMXoWHuynBzUX7TS6ST6yEr0tD+CBbCpbfcMuwTI3lNtfywEVpuFaeHqDZx2QDrEX4bg0dRKgQstbXYdqmBfnOiBpUr8Wyl8U1J24rN+E07pBw/8KDGWbVg19/Ex8o4ht/p5voUfKVjD/DwWXTLntBirjfAgQAm4GH/qP4x3zNiTtlYlQFbXSk6VEVrTrxCB5rTWvGnhg31tk5P3YwvagDmGABazY5s/8tlttSc1yWBctWQJCjxSqcCLekxG4D1rVuGKCKOZgflQ9QFdQlKycInPBek3zi0i3GYkE1YnNFye5ggOnxT8qGuKjfdtZI9qvMJQO8lbEDzbYQvNns1V/k4ZobiihYwrG5TJUzZFEpMYetDK6tI8BRU11d+ja0jWzguj5/7wc0nrr/BiZ8FkAr2fZ60j2aI5kG0s3qjbrQbB/RXaGP9hRU0+480+IokNJJIcjv5iwH5ophdrjC8GH4So2kPPt0NXob1yNysdjw== n0emis@noemis.me (OLD)"
    ];
  };
}

