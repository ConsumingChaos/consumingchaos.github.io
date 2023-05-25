load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_flake_package")

_CC_BUILD_FILE_CONTENT = """
package(default_visibility = ["//visibility:public"])

exports_files(["config.bzl"])
"""

_RUST_BUILD_FILE_CONTENT = """
load("@rules_rust//rust:toolchain.bzl", "rust_stdlib_filegroup")

package(default_visibility = ["//visibility:public"])

# https://github.com/tweag/rules_nixpkgs/blob/master/toolchains/rust/rust.bzl#L33-L116
filegroup(
    name = "rustc",
    srcs = ["bin/rustc"],
)

filegroup(
    name = "rustdoc",
    srcs = ["bin/rustdoc"],
)

filegroup(
    name = "rustfmt",
    srcs = ["bin/rustfmt"],
)

filegroup(
    name = "cargo",
    srcs = ["bin/cargo"],
)

filegroup(
    name = "clippy_driver",
    srcs = ["bin/clippy-driver"],
)

filegroup(
    name = "rustc_lib",
    srcs = glob(
        [
            "bin/*.so",
            "lib/*.so",
            "lib/rustlib/x86_64-unknown-linux-gnu/codegen-backends/*.so",
            "lib/rustlib/x86_64-unknown-linux-gnu/codegen-backends/*.dylib",
            "lib/rustlib/x86_64-unknown-linux-gnu/bin/*",
            "lib/rustlib/x86_64-unknown-linux-gnu/lib/*.so",
            "lib/rustlib/x86_64-unknown-linux-gnu/lib/*.dylib",
        ],
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-aarch64-apple-darwin",
    srcs = glob(
        [
            "rust/lib/rustlib/aarch64-apple-darwin/lib/*.rlib",
            "rust/lib/rustlib/aarch64-apple-darwin/lib/*.so",
            "rust/lib/rustlib/aarch64-apple-darwin/lib/*.dylib",
            "rust/lib/rustlib/aarch64-apple-darwin/lib/*.a",
            "rust/lib/rustlib/aarch64-apple-darwin/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-aarch64-apple-ios",
    srcs = glob(
        [
            "rust/lib/rustlib/aarch64-apple-ios/lib/*.rlib",
            "rust/lib/rustlib/aarch64-apple-ios/lib/*.so",
            "rust/lib/rustlib/aarch64-apple-ios/lib/*.dylib",
            "rust/lib/rustlib/aarch64-apple-ios/lib/*.a",
            "rust/lib/rustlib/aarch64-apple-ios/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-aarch64-linux-android",
    srcs = glob(
        [
            "rust/lib/rustlib/aarch64-linux-android/lib/*.rlib",
            "rust/lib/rustlib/aarch64-linux-android/lib/*.so",
            "rust/lib/rustlib/aarch64-linux-android/lib/*.dylib",
            "rust/lib/rustlib/aarch64-linux-android/lib/*.a",
            "rust/lib/rustlib/aarch64-linux-android/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-aarch64-unknown-linux-gnu",
    srcs = glob(
        [
            "rust/lib/rustlib/aarch64-unknown-linux-gnu/lib/*.rlib",
            "rust/lib/rustlib/aarch64-unknown-linux-gnu/lib/*.so",
            "rust/lib/rustlib/aarch64-unknown-linux-gnu/lib/*.dylib",
            "rust/lib/rustlib/aarch64-unknown-linux-gnu/lib/*.a",
            "rust/lib/rustlib/aarch64-unknown-linux-gnu/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-wasm32-unknown-unknown",
    srcs = glob(
        [
            "rust/lib/rustlib/wasm32-unknown-unknown/lib/*.rlib",
            "rust/lib/rustlib/wasm32-unknown-unknown/lib/*.so",
            "rust/lib/rustlib/wasm32-unknown-unknown/lib/*.dylib",
            "rust/lib/rustlib/wasm32-unknown-unknown/lib/*.a",
            "rust/lib/rustlib/wasm32-unknown-unknown/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-wasm32-wasi",
    srcs = glob(
        [
            "rust/lib/rustlib/wasm32-wasi/lib/*.rlib",
            "rust/lib/rustlib/wasm32-wasi/lib/*.so",
            "rust/lib/rustlib/wasm32-wasi/lib/*.dylib",
            "rust/lib/rustlib/wasm32-wasi/lib/*.a",
            "rust/lib/rustlib/wasm32-wasi/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-x86_64-apple-darwin",
    srcs = glob(
        [
            "rust/lib/rustlib/x86_64-apple-darwin/lib/*.rlib",
            "rust/lib/rustlib/x86_64-apple-darwin/lib/*.so",
            "rust/lib/rustlib/x86_64-apple-darwin/lib/*.dylib",
            "rust/lib/rustlib/x86_64-apple-darwin/lib/*.a",
            "rust/lib/rustlib/x86_64-apple-darwin/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-x86_64-pc-windows-msvc",
    srcs = glob(
        [
            "rust/lib/rustlib/x86_64-pc-windows-msvc/lib/*.rlib",
            "rust/lib/rustlib/x86_64-pc-windows-msvc/lib/*.so",
            "rust/lib/rustlib/x86_64-pc-windows-msvc/lib/*.dylib",
            "rust/lib/rustlib/x86_64-pc-windows-msvc/lib/*.a",
            "rust/lib/rustlib/x86_64-pc-windows-msvc/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)

rust_stdlib_filegroup(
    name = "rust_std-x86_64-unknown-linux-gnu",
    srcs = glob(
        [
            "rust/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.rlib",
            "rust/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.so",
            "rust/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.dylib",
            "rust/lib/rustlib/x86_64-unknown-linux-gnu/lib/*.a",
            "rust/lib/rustlib/x86_64-unknown-linux-gnu/lib/self-contained/**",
        ],
        # Some patterns (e.g. `lib/*.a`) don't match anything, see https://github.com/bazelbuild/rules_rust/pull/245
        allow_empty = True,
    ),
)
"""

def nix_repositories():
    nixpkgs_flake_package(
        name = "nix_config",
        nix_flake_file = "//:flake.nix",
        nix_flake_lock_file = "//:flake.lock",
        package = "bazel.config",
        build_file_content = _CC_BUILD_FILE_CONTENT,
    )

    nixpkgs_flake_package(
        name = "nix_rust",
        nix_flake_file = "//:flake.nix",
        nix_flake_lock_file = "//:flake.lock",
        package = "bazel.rust",
        build_file_content = _RUST_BUILD_FILE_CONTENT,
    )
