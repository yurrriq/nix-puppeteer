{ nixpkgs ? <nixpkgs> }:

with import nixpkgs {
  config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nodejs = pkgs.nodejs-8_x;
      nodePackages = pkgs.nodePackages //
        pkgs.callPackage ./pkgs/development/node-packages {};
    };
  };
};

dockerTools.buildImage {
  name = "yurrriq/nix-puppeteer";
  tag = builtins.readFile ./VERSION;

  contents = [
    nodejs
    nodePackages.puppeteer
  ];

  runAsRoot = ''
    #! ${stdenv.shell}
    ${dockerTools.shadowSetup}
    groupadd -r audio
    groupadd -r video
    groupadd -r pptruser
    useradd -r -g pptruser -G audio,video pptruser
    mkdir -p /home/pptruser/Downloads
    chown -R pptruser:pptruser /home/pptruser
    # chown -R pptruser:pptruser /node_modules
  '';

  config = {
    User = "pptruser";
    Env = [
      "NODE_PATH=${nodejs}/lib/node_modules:${nodePackages.puppeteer}/lib/node_modules"
    ];
    Cmd = [ "${nodejs}/bin/node" ];
  };
}
