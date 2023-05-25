---
title: "Cross Compiled Bevy"
date: 2023-12-15T18:00:00-07:00
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

# [Example Code](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy)

# Motivation

Building on [Nix + Bazel Cross Compiling]({{< ref "/posts/nix-bazel-cross-compiling.md" >}}), my next step is to build something of substance to make sure the cross compiling toolchains actually work. I've chosen [Bevy](https://bevyengine.org/) as it's a non-trivial project that also has dependencies on C/C++ source code and OS libraries.

My test case is making sure the following Bevy Hello World can build successfully:

```rust
use bevy::prelude::*;

fn main()
{
    App::new().add_plugins(DefaultPlugins).run();
}
```

I've tested to make sure the Hello World runs on Windows/MacOS, but I don't have a non-DevServer Linux machine and bundling on Android/iOS is out of scope for the post.

# Crate Universe

I'm using [Crate Universe](https://bazelbuild.github.io/rules_rust/crate_universe.html) as my Bazel + Cargo bridge. I had some previous experience with [cargo-raze](https://github.com/google/cargo-raze), but Crate Universe is the official [rules_rust](https://github.com/bazelbuild/rules_rust) solution and is more mature and feature rich.

Crate Universe allows me to fully express Cargo dependencies in Bazel via [crate.spec](https://bazelbuild.github.io/rules_rust/crate_universe.html#cratespec) (and patch them via [crate.annotation](https://bazelbuild.github.io/rules_rust/crate_universe.html#crateannotation)), instead of needing to maintain a `Cargo.toml` and write crate annotations in TOML which can be a bit awkward compared to crate annotations in Starlark.

Crate Universe relies on the [cargo-bazel](https://crates.io/crates/cargo-bazel) CLI. Like with most things on NixOS, this requires a bit of patching to work. The solution I'm using is to have my Nix Flake provide the binary via [rustPlatform.buildRustPackage](https://nixos.org/manual/nixpkgs/stable/#compiling-rust-applications-with-cargo), pull it into Bazel with [nixpkgs_flake_package](https://github.com/tweag/rules_nixpkgs#nixpkgs_flake_package), and then provide it via the `generator` parameter of [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-generator).

# Cargo Feature Resolver

Bevy relies on the new [Cargo feature resolver](https://doc.rust-lang.org/edition-guide/rust-2021/default-cargo-resolver.html). For Crate Universe to use it, the following `splicing_config` needs to be provided to [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-splicing_config)

```python
splicing_config(
   resolver_version = "2",
)
```

# Default Alias Rule

To try to strike a balance between development build performance and debuggability, I'm setting `default_alias_rule = "opt"` on the `render_config` being provided to [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-render_config). This causes any Crate Universe dependencies to be built in an optimized configuration regardless of the configuration of the local project.

```python
render_config(
   default_alias_rule = "opt",
)
```

The rationale here is that Bevy can be treated as a black box (as would be the case for any dependency that doesn't come with source code/symbols) and therefore isn't normally expected to be debugged. If debugging Bevy is needed, `default_alias_rule` can always be commented off and it will build in whatever configuration is specified.

# Cargo Build Scripts

Philosophically I oppose [Cargo build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html) for being an opaque escape hatch that's impossible to reason about (without reverse engineering the scripts). As such, I've made a point of setting `generate_build_scripts = False` on [crates_repository](https://bazelbuild.github.io/rules_rust/crate_universe.html#crates_repository-generate_build_scripts). Most of the `crate.annotation`s in the example work fine with [cargo_build_script](https://bazelbuild.github.io/rules_rust/cargo.html#cargo_build_script) as they're generally not compiling C/C++ code or doing anything too crazy, but on principle I opted to do this the "hard way" that lets me sleep more soundly at night.

The following crates were annotated in lieu of using `cargo_build_script`.

{{< details "alsa-sys" >}}

`alsa-sys` just needs to link in a prebuilt dynamic system library. This is done by declaring a dependency on a local target [@//bazel/platforms/linux:alsa](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/platforms/linux/BUILD.bazel) which is a trivial `cc_library()` target that adds `-lasound` to `linkopts`. The headers are already present in the SDK and part of the toolchain's system include paths.

{{< /details >}}

{{< details "blake3" >}}

`blake3` involved reverse engineering [build.rs](https://github.com/BLAKE3-team/BLAKE3/blob/master/build.rs). This lead to two pieces, a set of `cfg` flags based on architecture (`x86_64` or `aarch64`), and dependencies on either linking in some prebuilt assembly code (x86_64) or compiling a small C library (`aarch64`). The only gotcha I ran into here is using the "Unix" set of files for Windows instead of the "Windows" set, as I'm using Clang+LLVM which understands the former but not the latter.

{{< /details >}}

{{< details "coreaudio-sys" >}}

`coreaudio-sys` relies on two things:

Firstly, [bindgen](https://rust-lang.github.io/rust-bindgen/) to generate bindings based on some headers in the Darwin/iOS SDKs. As the [rust_bindgen](https://bazelbuild.github.io/rules_rust/rust_bindgen.html#rust_bindgen) rule in `rules_rust` isn't set up to work with my cross compilation setup, I opted to write my own [rust_bindgen.bzl](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/rules/rust_bindgen.bzl) that uses a Nix provided `bindgen` CLI and knows to pass the appropriate include paths for the Nix provided SDKs.

Secondly, linking to some system frameworks. This is done by declaring a dependency on a local target [@//bazel/platforms/apple:AudioToolbox|AudioUnit|CoreAudio](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/platforms/BUILD.bazel) which are trivial `cc_library()` targets that add `-framework AudioToolbox|AudioUnit|CoreAudio` to `linkopts`.

{{< /details >}}

{{< details "gilrs" >}}

`gilrs` needs a generated file provided to it. In the process of trying to figure out how the file was generated per platform, I realized that the generation step just stripped out values for other platforms, which the library also does at load time. For simplicity sake given the small size of the data, I opted to just directly copy the un-stripped source file to `OUT_DIR` using my [directorygroup](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/rules/directorygroup.bzl) rule.

{{< /details >}}

{{< details "indexmap-1.9.3" >}}

`indexmap (1.9.3)` does some trivial checking to see whether or not it's being built with `std`, so I just always supply the `cfg` flag `has_std`.

{{< /details >}}

{{< details "libc" >}}

`libc` does some platform detection and `rustc` available feature detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/rust-lang/libc/blob/main/build.rs).

{{< /details >}}

{{< details "libudev-sys" >}}

`libudev-sys` just needs to link in a prebuilt dynamic system library. This is done by declaring a dependency on a local target [@//bazel/platforms/linux:udev](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/platforms/linux/BUILD.bazel) which is a trivial `cc_library()` target that adds `-ludev` to `linkopts`. The headers are already present in the SDK and part of the toolchain's system include paths.

{{< /details >}}

{{< details "num-integer" >}}

`num-integer` does some `rustc` available feature detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/rust-num/num-integer/blob/num-integer-0.1.45/build.rs). This is evidently no longer necessary on [master](https://github.com/rust-num/num-integer/blob/master/Cargo.toml).

{{< /details >}}

{{< details "num-rational" >}}

`num-rational` does some `rustc` available feature detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/rust-num/num-rational/blob/master/build.rs).

{{< /details >}}

{{< details "num-traits" >}}

`num-traits` does some `rustc` available feature detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/rust-num/num-traits/blob/master/build.rs).

{{< /details >}}

{{< details "objc-sys" >}}

`objc-sys` relies on two things:

Firstly, linking in a prebuilt dynamic system library. This is done by declaring a dependency on a local target [@//bazel/platforms/apple:objc](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/platforms/apple/BUILD.bazel) which is a trivial `cc_library()` target that adds `-lobjc` to `linkopts`.

Secondly, does some platform detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/madsmtm/objc2/blob/objc-sys-0.2.0-beta.2/objc-sys/build.rs). The `objc-sys` crate only exists in the tagged release branches, not on `master`.

{{< /details >}}

{{< details "proc-macro2" >}}

`proc-macro2` does some `rustc` available feature detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/dtolnay/proc-macro2/blob/master/build.rs).

{{< /details >}}

{{< details "syn" >}}

`syn` oddily enough doesn't seem to resolve the crate features it should. I've just manually turned them on based on what is available in [Cargo.toml](https://github.com/dtolnay/syn/blob/master/Cargo.toml).

{{< /details >}}

{{< details "winapi" >}}

`winapi` relies on two things:

Firstly, linking in some prebuilt dynamic system libraries. This is done by declaring dependencies on a local target [@//bazel/platforms/windows:\*](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/main/examples/cross-compiled-bevy/bazel/platforms/windows/BUILD.bazel) which are trivial `cc_library()` target that add `<library>.lib` to `linkopts`.

Secondly, every namespace in `winapi` is gated behind a crate feature. This was filled in via whack-a-mole, where everytime there is a `winapi::x module not found` error, I add `x` to the list of `crate_features`.

{{< /details >}}

{{< details "windows_x86_64_msvc-0.42.2" >}}

`windows_x86_64_msvc (0.42.2)` and `windows_x86_64_msvc (0.48.5)` need identical annotations but with different name mangling. Both come bundled with a prebuilt library, so the crates are annotated to depend on some trivial `cc_library()` targets that list the bundled prebuilt library under `srcs`.

{{< /details >}}

{{< details "winit" >}}

`winit` does some platform detection. This is easy enough to fill in via reverse engineering [build.rs](https://github.com/rust-windowing/winit/blob/master/build.rs).

{{< /details >}}

{{< details "x11-dl" >}}

`x11-dl` does some `pkgconfig` checking for libraries and then generates `config.rs` that specifies the path to each. I manually generated `config.rs` by checking if each library was present in the `x86_64-unknown-linux-gnu` SDK and if so emitting either `pub const <package>: Option<&'static str> = Some("/usr/lib/x86_64-linux-gnu/");` or `pub const <package>: Option<&'static str> = None;`. The list of packages being checked is nicely grouped in [build.rs](https://github.com/AltF02/x11-rs/blob/master/x11-dl/build.rs).

{{< /details >}}
