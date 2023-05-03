---
title: "Nix + Bazel Crosspiling"
date: 2023-06-05T14:00:00-07:00
author: James Leitch
tags:
  - nix
  - nixpkgs
  - bazel
  - crosspile
  - crosspiling
  - toolchain
  - platform
  - rust
  - c++
  - cxx
  - cc
---

# [Example Code](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling)

# Motivation

For years now, I've had "learn and set up crosspiling" as personal backlog item. From my career observations, there is often a lot of developer pain and efficiency lost when a project is targeting multiple platforms. Some examples that come to mind:

- Having to switch developer machines and synchronize code across them.
- Having to rig up some form of individual remote compilation and teach everyone how to use it (for example, having Windows sync the repo to Mac, run the build on Mac, and report back the results).
- Relying on continuous integration to build non-host platforms and not having coverage during normal developer iteration.

Conversely, I see some major upsides to crosspiling:

- Running "build all" can actually build **all**.
- Developer environments can be standardized to a single development environment (like a Linux [DevServer]({{< ref "/posts/nixos-devserver.md" >}})).
- Automation infrastructure (like continuous integration) can also be standardized to the same single development environment.

With these motivations in mind, the question becomes, how do I actually set this up? From the reading and searching I've done, I had a hard time finding a concise and clear example of crosspiling "from scratch". This was particularly evident with my preferred choice of package management and build system, Nix and Bazel respectively. Hopefully this post can help serve as such an example.

For background information and motivation on why Nix + Bazel, I recommend reading <https://www.tweag.io/blog/2018-03-15-bazel-nix/>.

# Nix

Nix is the package manager providing all the tools and SDKs needed to crosspile code. To pull this off, my [Nix Flake](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/flake.nix) exposes two things: a `devShell` (making tools available in the terminal and VSCode) and a set `bazel` that contains derivations that get exposed to Bazel via [rules_nixpkgs](https://github.com/tweag/rules_nixpkgs). Keeping everything in the same Nix Flake lets me ensure there is only one set of tools/SDKs and that they're shared between the developer environment and Bazel.

The main derivation is `bazel.config` which generates `config.bzl`, a Bazel file containing all of the Nix store paths I need exposed to Bazel. I opted to use absolute paths (where possible) for Nix provided packages because they are already content addressed, so any change to them will result in a new path, which in turn will invalidate Bazel's cache. Unfortunately this won't work with Bazel remote execution, but `rules_nixpkgs` doesn't support remote execution presently anyways. On the flip side, this skips the need for Bazel to make a giant symlink forest for each package, and in the case of some of the SDKs, works around the issue where they contain recursive symlinks, which Bazel chokes on.

## SDKs

Below are my rough instructions for acquiring the SDKs to each platform targeted in this post. The Apple and Microsoft SDKs cannot be hosted publicly, so it's left up to the reader to make them privately available for their project.

**aarch64-unknown-linux-gnu**

Downloaded from Chromium project. Reverse engineered from https://chromium.googlesource.com/chromium/src/build/+/refs/heads/main/linux/sysroot_scripts/install-sysroot.py

1. Get `Sha1Sum` for `debian_{version}_arm64_sysroot.tar` from https://chromium.googlesource.com/chromium/src/build/+/refs/heads/main/linux/sysroot_scripts/sysroots.json
2. Fill in URL `https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/`
   `{Sha1Sum}/debian_{version}_arm64_sysroot.tar.xz`

**universal-apple-darwin**

Pulled from Xcode installation on a Mac.

1. Run `(export OUTPUT=${PWD}/universal-apple-darwin/{version}.tar.xz`
   `&& cd $(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX{version}.sdk`
   `&& tar -cvJf ${OUTPUT} .)`

**universal-apple-ios**

Pulled from Xcode installation on a Mac.

1. Run `(export OUTPUT=${PWD}/universal-apple-ios/{version}.tar.xz`
   `&& cd $(xcode-select -p)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS{version}.sdk`
   `&& tar -cvJf ${OUTPUT} .)`

**universal-linux-android**

Android NDK from https://developer.android.com/ndk/downloads

**wasm32-unknown-unknown**

By definition this shouldn't really require an SDK, but it does require `libclang_rt.builtins-*` which exist as a prebuilt in the `wasm32-wasi` SDK. See the `wasm32-wasi` SDK section.

**wasm32-wasi**

Download SDK and `libclang_rt.builtins-*`.
https://github.com/WebAssembly/wasi-sdk/releases

**x86_64-pc-windows-msvc**

Generated via `xwin` tool. See https://jake-shadle.github.io/xwin/

1. Install `xwin` by running `cargo install --locked xwin`
2. Run `(export OUTPUT=${PWD}/x86_64-pc-windows-msvc/{version}.tar.xz`
   `&& rm -rf /tmp/xwin`
   `&& mkdir /tmp/xwin`
   `&& xwin --accept-license --manifest-version {version} --temp splat --output /tmp/xwin`
   `&& cd /tmp/xwin && tar -cvJf ${OUTPUT} .`
   `&& rm -rf /tmp/xwin)`

**x86_64-unknown-linux-gnu**

Downloaded from Chromium project. Reverse engineered from https://chromium.googlesource.com/chromium/src/build/+/refs/heads/main/linux/sysroot_scripts/install-sysroot.py

1. Get `Sha1Sum` for `debian_{version}_amd64_sysroot.tar` from https://chromium.googlesource.com/chromium/src/build/+/refs/heads/main/linux/sysroot_scripts/sysroots.json
2. Fill in URL `https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/`
   `{Sha1Sum}/debian_{version}_amd64_sysroot.tar.xz`

**x86_64-unknown-nixos-gnu**

Directly assembled from Nix packages inside of `flake.nix`.

# Bazel

Bazel uses all of the tools and SDKs exposed by Nix to build C/C++ and Rust code. All the Nix derivations under the `bazel` set are imported into the Bazel Workspace with [nixpkgs_flake_package](https://github.com/tweag/rules_nixpkgs#nixpkgs_flake_package). From there, a collection of Bazel toolchains are configured and registered.

Unfortunately I couldn't figure out a way to configure C/C++ toolchains using Bazel's existing helper functions that I was happy with, so I ended up avoiding the Bazel "feature" system and configuring actions from scratch. While this lacks the dynamic configurability in the default Bazel C/C++ toolchains, I think it's a lot easier to follow and philosophically I try to keep as much out of Bazel CLI/`.bazelrc` flags as possible. I prefer to express things in the build graph when possible as I think it's easier to reason about and avoids invalidating Bazel's action graph cache and output cache when different sets of options are required.

C/C++ toolchains are configured using the helpers in [//bazel/toolchain_rules](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules). The main interface is the top level [llvm_cc_toolchain_config](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/llvm_cc_toolchain_config.bzl) function. Based on the supplied `target` it delegates constructing the `action_config`s to the appropriate tool. For compilation, this is always [clang](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/clang.bzl), and for archiving and stripping [llvm-ar](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/llvm-ar.bzl) and [llvm-strip](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/llvm-strip.bzl) respectively, but for linking it's split between the different linker "flavors":

- [ld.lld](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/ld.lld.bzl) for Linux/Android
- [ld64.lld](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/ld64.lld.bzl) for Apple
- [lld-link](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/lld-link.bzl) for Windows (MSVC)
- [wasm-ld](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchain_rules/cc_tools/wasm-ld.bzl) for WASM

The actual toolchain configurations are located under [//bazel/toolchains/cc](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchains/cc), grouped by platform.

Rust toolchains, by comparison, are much easier to register. The Nix Flake provides a Rust toolchain with the standard library prebuilt per target platform, so the actual Bazel configuration is minimal. The Rust toolchain configurations are located under [//bazel/toolchains/rust](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/toolchains/rust), grouped by platform.

**IMPORTANT NOTE**: The toolchain configurations (mainly the C/C++ ones) should just be taken as examples. They have not been used in production and only validated in the Bazel `fastbuild` configuration. They should be thought of as a starting point for configuring your own toolchains.

# Platform "Missing"

Philosophically I want to avoid having varying sets of command line arguments to Bazel. Normally to build for different platforms, you'd supply `--platforms=<platform label>` on the command line (or in a `.bazelrc`). Selecting platforms this way has two notable issues I want to avoid. First, it invalidates the Bazel action cache (so switching platforms is a lot of recomputation) and invalidates the output directory. Second, it means that a single build invocation can't "build all" across platforms.

Instead of using the command line option, I'm relying on [configuration transitions](https://bazel.build/extending/config#user-defined-transitions) to represent all the platforms in a single build graph. However by default `bazel build //...` will end up targeting both the targets that are after the transition and the targets before (which then use the command line platform, defaulting to host platform if absent). My solution to this is to tag all pre-transition rules with a tag that excludes them from "build all" and put `build --platforms=//bazel/platforms:missing` in [.bazelrc](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/.bazelrc) to catch any rules I forget (which will error with roughly "no toolchain found for platform missing"). Normally in Bazel the tag `manual` does is used to prevent inclusion in target globs (like `//...`).

However, I've been tagging most rules with `platform_missing` instead and using `build --build_tag_filters=-platform_missing` in `.bazelrc` to filter those out as well. The rationale here is there doesn't seem to be a way to include `manual` in a glob, which is sometimes relevant for aspects, whereas `platform_missing` can be included by removing the tag filter. I'm somewhat optimistic this will go away and I'll go back to `manual` if it's possible to have `rules_rust`'s Rust Analyzer aspect traverse the transition rules instead of relying on directly globbing the Rust rules.

# Example Apps

The example includes a very basic set of Hello World apps (one C++ based, one Rust based). The targets use [aspect_bazel_lib](https://github.com/aspect-build/bazel-lib)'s [platform_transition_binary](https://github.com/aspect-build/bazel-lib/blob/main/docs/transitions.md#platform_transition_binary) rule to transition to each of the platforms defined in [//bazel/platforms](https://github.com/ConsumingChaos/consumingchaos.github.io/tree/master/examples/nix-bazel-crosspiling/bazel/platforms).
