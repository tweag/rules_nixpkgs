{ ... }:
let 
  nixpkgs = import <nixpkgs> {};
  openssl-static = nixpkgs.openssl.override {
    static = true;
  };
in
  nixpkgs.symlinkJoin { 
    name = "openssl-static.bzl";
    paths = [ 
        openssl-static.dev
        openssl-static.out
    ];
}
