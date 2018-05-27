# nix-puppeteer

[![Build Status][Travis badge]][Travis link]

*[Nix][1]-based [Docker][2] image with [Puppeteer][3]*

## Build Docker Image

```fish
docker load <(nix-build -A docker --no-out-link)
```

## Example

Create the `docs` directory and make sure the `pptuser` can write to it.

```fish
mkdir -p docs
chmod a+w docs
```

Run the example to generate [the screenshot][4].

```fish
docker run --rm \
  -v "$PWD/docs":/docs \
  -w /docs \
  yurrriq/nix-puppeteer:0.0.1
```




<!-- Named Links -->

[Travis badge]: https://travis-ci.org/yurrriq/nix-puppeteer.svg?branch=master
[Travis link]: https://travis-ci.org/yurrriq/nix-puppeteer
[1]: https://nixos.org/nix/
[2]: https://www.docker.com/
[3]: https://github.com/GoogleChrome/puppeteer/
[4]: ./docs/example.png
