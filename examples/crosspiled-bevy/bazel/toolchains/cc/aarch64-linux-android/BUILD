load(
    "@nix_config//:config.bzl",
    "BINUTILS",
    "CLANG",
    "CLANG_LIB",
    "CLANG_LIB_VERSION",
    "SDK_AARCH64_LINUX_ANDROID",
)
load("//bazel/toolchain_rules:llvm_cc_toolchain_config.bzl", "llvm_cc_toolchain_config")

llvm_cc_toolchain_config(
    name = "cc_toolchain_config",
    archive_flags = [],
    binutils = BINUTILS,
    builtin_executable_objects = [
        ":crtbegin_dynamic.o",
        ":crtend_android.o",
    ],
    builtin_include_directories = [
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/c++/v1".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/lib/clang/{}/include".format(CLANG_LIB, CLANG_LIB_VERSION),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/local/include".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/aarch64-linux-android".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include".format(SDK_AARCH64_LINUX_ANDROID),
    ],
    builtin_libraries = [
        "c",
        "dl",
        "m",
        "unwind",
        "stdc++",
        "c++",
        "c++abi",
    ],
    builtin_library_directories = [
        "{}/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.7".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.7/lib/linux/aarch64".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/24".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android".format(SDK_AARCH64_LINUX_ANDROID),
        "{}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib".format(SDK_AARCH64_LINUX_ANDROID),
    ],
    clang = CLANG,
    compile_flags = [
        "-DANDROID",
        "-D_FORTIFY_SOURCE=2",
        "-fdata-sections",
        "-ffunction-sections",
        "-fno-exceptions",
        "-fstack-protector-strong",
        "-funwind-tables",
        "-no-canonical-prefixes",
        "-Wall",
        "-Werror",
        "-Werror=format-security",
        "-Wformat",
        "-Wself-assign",
        "-Wthread-safety",
    ],
    dbg_compile_flags = [
        "-g",
        "-fno-limit-debug-info",
    ],
    dbg_link_flags = [],
    fastbuild_compile_flags = [],
    fastbuild_link_flags = [],
    link_flags = [
        "--fatal-warnings",
        "--sysroot={}/toolchains/llvm/prebuilt/linux-x86_64/sysroot".format(SDK_AARCH64_LINUX_ANDROID),
        "--dynamic-linker=/system/bin/linker64",
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
    target = "aarch64-linux-android",
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
        "@platforms//cpu:aarch64",
        "@platforms//os:android",
    ],
    toolchain = ":cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
