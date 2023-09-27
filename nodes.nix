{ lib, inputs, ... }:

{
  defaults = {
    specialArgs = { inherit inputs; };
    nixpkgs = lib.mkDefault inputs.nixpkgs;
    configuration = import ./profiles/base;
  };

  nodes = {
    martian.configuration = import ./hosts/martian;
    franzbroetchen.configuration = import ./hosts/franzbroetchen;
    merkur.configuration = import ./hosts/merkur;
  };
}
