{ inputs, ... }: {
  imports = [
    inputs.leona-nixfiles.nixosModules.leona-profile
  ];
}
