---
title: "Cross Compiled Bevy"
date: 2023-05-24T18:00:00-07:00
author: James Leitch
tags:
  - bazel
  - cross compile
  - cross compiling
  - platform
  - rust
  - bevy
  - videogame
---

# [Example Code](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/cross-compiled-bevy)\*\*

# Motivation

Building on [Nix + Bazel Cross Compiling]({{< ref "/posts/nix-bazel-cross-compiling.md" >}}), my next step is to build something of substance to make sure the cross compiling toolchains actually work. As I'm planning to play around with [Bevy](https://bevyengine.org/) and it's a non-trivial project, it seemed like the perfect fit. My test case is making sure the following Bevy Hello World can build successfully:

```rust
use bevy::prelude::*;

fn main()
{
    App::new().add_plugins(DefaultPlugins).run();
}
```

I've tested to make sure the Hello World runs on Windows/MacOS/Linux, but bundling and running on Android/iOS is out of scope for the post.

# Crate Universe

I've opted to use [Crate Universe](https://bazelbuild.github.io/rules_rust/crate_universe.html) as my Bazel + Cargo bridge. I have some previous experience with [cargo-raze](https://github.com/google/cargo-raze), but Crate Universe being the more official [rules_rust](https://github.com/bazelbuild/rules_rust) solution and being able to fully express Cargo dependencies in Bazel via [crate.spec](https://bazelbuild.github.io/rules_rust/crate_universe.html#cratespec) (and patch them via [crate.annotation](https://bazelbuild.github.io/rules_rust/crate_universe.html#crateannotation)) won me over. After getting more exposure to Crate Universe and working to upstream some features to it, I think it was definitely the right choice.

Crate Universe relies on the [cargo-bazel](https://crates.io/crates/cargo-bazel) CLI. Like with most things on NixOS, this requires a bit of patching to work. The solution I'm using is to have my Nix Flake provide the binary via [rustPlatform.buildRustPackage](https://nixos.org/manual/nixpkgs/stable/#compiling-rust-applications-with-cargo), pull it into Bazel with [nixpkgs_flake_package](https://github.com/tweag/rules_nixpkgs#nixpkgs_flake_package), and then provide it via the `generator` parameter of [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-generator).

# Cargo Feature Resolver

Bevy relies on the new [Cargo feature resolver](https://doc.rust-lang.org/edition-guide/rust-2021/default-cargo-resolver.html). For Crate Universe to use it, the following `splicing_config` needs to be provided to [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-splicing_config)

```python
splicing_config(
   resolver_version = "2",
)
```

# Cargo Build Scripts

Philosophically I oppose [Cargo build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html) for being an opaque escape hatch that's impossible to reason about (without reverse engineering the scripts). As such, I've made a point of setting `generate_build_scripts = False` on [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-generate_build_scripts). Most of the `crate.annotation`s in the example work fine with [cargo_build_script](https://bazelbuild.github.io/rules_rust/cargo.html#cargo_build_script) as they're generally not compiling C/C++ code or doing anything too crazy, but on principle I opted to do this the "hard way" that lets me sleep more soundly at night.

# Platforms

To support NixOS as a distinct platform, I had to make use of `platforms_template` in [render_config](https://bazelbuild.github.io/rules_rust/crate_universe.html#render_config-platforms_template) so that I could provide my own set of `config_setting`s as there isn't an LLVM target triple for [@platforms//os:nixos](https://github.com/bazelbuild/platforms/blob/main/os/BUILD). My solution was to use the following so that a `select()` for `x86_64-unknown-linux-gnu` worked for both `//bazel/platforms:x86_64-unknown-linux-gnu` and `//bazel/platforms:x86_64-unknown-nixos-gnu`.

```python
load("@bazel_skylib//lib:selects.bzl", "selects")

selects.config_setting_group(
    name = "x86_64-unknown-linux-gnu",
    match_any = [
        ":x86_64-unknown-linux-gnu_linux",
        ":x86_64-unknown-linux-gnu_nixos",
    ],
)

config_setting(
    name = "x86_64-unknown-linux-gnu_linux",
    constraint_values = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

config_setting(
    name = "x86_64-unknown-linux-gnu_nixos",
    constraint_values = [
        "@platforms//cpu:x86_64",
        "@platforms//os:nixos",
    ],
)
```
