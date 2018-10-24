# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.3.1] - 2018-10-24

### Fixed

* `repositories` is no longer a required argument to `nixpkgs_package`.

## [0.3] - 2018-10-23

### Added

* `nixpkgks_package` now supports referencing arbitrarily named nix
  files. A bug previously only made it possible to reference
  `default.nix` files.

### Removed

* The `path` attribute has been removed. See `Migration` section
  in `README.md` for instructions.

### Changed

* `nixpkgs_packages` does not accept implicit `<nixpkgs>` version. See
   [#25](https://github.com/tweag/rules_nixpkgs/pull/25).

## [0.2.3] - 2018-07-01

### Added

* `sha256` attribute to `nixpkgs_git_repository`.
* Ability to point to a Nixpkgs fork via the new `remote` attribute to
  `nixpkgs_git_repository`.

## [0.2.2] - 2018-04-30

## [0.2.1] - 2018-03-18

## [0.2] - 2018-03-18

## [0.1] - 2018-02-21

## [0.1.1] - 2017-12-27
