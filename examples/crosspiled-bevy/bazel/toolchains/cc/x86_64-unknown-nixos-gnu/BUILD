load(
    "@nix_config//:config.bzl",
    "BINUTILS",
    "CLANG",
    "CLANG_LIB",
    "CLANG_LIB_VERSION",
    "SDK_X86_64_UNKNOWN_NIXOS_GNU",
)
load("//bazel/toolchain_rules:llvm_cc_toolchain_config.bzl", "llvm_cc_toolchain_config")

llvm_cc_toolchain_config(
    name = "cc_toolchain_config",
    archive_flags = [],
    binutils = BINUTILS,
    builtin_executable_objects = [
        ":Scrt1.o",
        ":crti.o",
        ":crtbeginS.o",
        ":crtendS.o",
        ":crtn.o",
    ],
    builtin_include_directories = [
        "{}/include/c++/v1".format(SDK_X86_64_UNKNOWN_NIXOS_GNU),
        "{}/lib/clang/{}/include".format(CLANG_LIB, CLANG_LIB_VERSION),
        "{}/include".format(SDK_X86_64_UNKNOWN_NIXOS_GNU),
    ],
    builtin_libraries = [
        ":libunwind.a",
        ":libc.so",
        ":libc++.a",
        ":libc++abi.a",
        "dl",
        "m",
        "pthread",
    ],
    builtin_library_directories = [
        "{}/lib".format(SDK_X86_64_UNKNOWN_NIXOS_GNU),
    ],
    clang = CLANG,
    compile_flags = [
        "-fno-exceptions",
        "-Werror",
        "-Wall",
        "-Wthread-safety",
        "-Wself-assign",
    ],
    dbg_compile_flags = [],
    dbg_link_flags = [],
    fastbuild_compile_flags = [],
    fastbuild_link_flags = [],
    link_flags = [
        "--fatal-warnings",
        "--dynamic-linker={}/lib64/ld-linux-x86-64.so.2".format(SDK_X86_64_UNKNOWN_NIXOS_GNU),
        "--build-id=md5",
        "--hash-style=gnu",
        "-z",
        "relro",
        "-z",
        "now",
    ],
    opt_compile_flags = [],
    opt_link_flags = [
        "--gc-sections",
    ],
    target = "x86_64-unknown-linux-gnu",
)

cc_toolchain(
    name = "cc_toolchain",
    all_files = "@nix_config//:config.bzl",
    ar_files = "@nix_config//:config.bzl",
    as_files = "@nix_config//:config.bzl",
    compiler_files = "@nix_config//:config.bzl",
    coverage_files = "@nix_config//:config.bzl",
    dwp_files = "@nix_config//:config.bzl",
    linker_files = "@nix_config//:config.bzl",
    objcopy_files = "@nix_config//:config.bzl",
    strip_files = "@nix_config//:config.bzl",
    toolchain_config = "cc_toolchain_config",
)

toolchain(
    name = "toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:nixos",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:nixos",
    ],
    toolchain = ":cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
