{ pkgs, ... }:

with pkgs;

let
  cloudsend = stdenv.mkDerivation {
  name = "cloudsend";
  src = fetchurl {
    url = "https://raw.githubusercontent.com/tavinus/cloudsend.sh/v2.2.8/cloudsend.sh"; 
    sha256 = "aa3c7983c1036f7bb29344df844a4eae4b4604d8c645c45d1bf50d4d02589421";
  }; 
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out
    install -Dm755 $src $out/bin/cloudsend.sh
  '';
  };
in

{
  packages = [
    coreboot-utils
    pciutils
    usbutils
    dmidecode
    dmidecode
    acpica-tools
    i2c-tools
    flashrom
    cloudsend
  ];

 enterShell = ''
   sudo env "PATH=$PATH" ./src/dts.sh 
 '';

  pre-commit.hooks = {
    # lint shell scripts
    shellcheck.enable = true;
  };
}
