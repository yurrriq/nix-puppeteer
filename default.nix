{ nixpkgs ? <nixpkgs> }:

with import nixpkgs {
  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      dumb-init = (import ./pkgs/tools/misc/dumb-init {}).packages.dumb-init;
      nodejs = pkgs.nodejs-8_x;
      nodePackages = pkgs.nodePackages //
        pkgs.callPackage ./pkgs/development/node-packages {};
    };
  };
};

let
  version = builtins.readFile ./VERSION;

  homepage = https://github.com/yurrriq/nix-puppeteer;

  example-js = writeText "example.js" ''
    const puppeteer = require('puppeteer');

    (async () => {
      const browser = await puppeteer.launch({
        executablePath: '${google-chrome-dev}/bin/google-chrome-unstable',
        args: [ '--no-sandbox' ]
      });
      const page = await browser.newPage();
      await page.goto('${homepage}');
      await page.screenshot({path: 'example.png'});

      await browser.close();
    })();
  '';

  example = writeShellScriptBin "example" ''
    ${nodejs}/bin/node ${example-js}
  '';

  buildInputs = [
    coreutils
    dumb-init
    example
    google-chrome-dev
    nodejs
    nodePackages.puppeteer
  ];

  NODE_PATH = "${nodejs}/lib/node_modules:${nodePackages.puppeteer}/lib/node_modules";

  fontsConf = makeFontsConf {
    fontDirectories = [];
  };

in

{
  docker = dockerTools.buildImage {
    name = "yurrriq/nix-puppeteer";
    tag = version;

    contents = buildInputs ++ [ bashInteractive ];

    runAsRoot = ''
      #! ${stdenv.shell}
      ${dockerTools.shadowSetup}
      groupadd -r audio
      groupadd -r video
      groupadd -r pptruser
      useradd -r -g pptruser -G audio,video pptruser
      mkdir -p /home/pptruser/Downloads
      chown -R pptruser:pptruser /home/pptruser
      mkdir -p /tmp
      chown -R pptruser:pptruser /tmp
    '';

    config = {
      User = "pptruser";
      Env = [
        "FONTCONFIG_FILE=${fontsConf}"
        "NODE_PATH=${NODE_PATH}"
      ];
      Entrypoint = [ "${dumb-init}/bin/dumb-init" "--" ];
      Cmd = [ "${example}/bin/example" ];
    };
  };

  drv = stdenv.mkDerivation rec {
    name = "nix-puppeteer-${version}";
    inherit version buildInputs;
    nativeBuildInputs = [ makeWrapper ];

    src = ./.;

    dontBuild = true;

    installPhase = ''
      makeWrapper ${example}/bin/example $out/bin/example \
        --set FONTCONFIG_FILE '${FONTCONFIG_FILE}' \
        --set NODE_PATH '${NODE_PATH}'
    '';

    meta = with stdenv.lib; {
      description = "Nix-based Docker image with Puppeteer";
      inherit homepage;
      license = licenses.mit;
      maintainers = with maintainers; [ yurrriq ];
      platforms = platforms.all;
    };
  };
}
