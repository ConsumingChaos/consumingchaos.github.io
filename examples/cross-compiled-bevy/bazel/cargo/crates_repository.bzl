""" Crate Universe Packages and Annotations """

load("@rules_rust//crate_universe:defs.bzl", "crate")
load("//bazel/cargo/crates:alsa-sys.bzl", alsa_sys = "ANNOTATION")
load("//bazel/cargo/crates:blake3.bzl", blake3 = "ANNOTATION")
load("//bazel/cargo/crates:coreaudio-sys.bzl", coreaudio_sys = "ANNOTATION")
load("//bazel/cargo/crates:gilrs.bzl", gilrs = "ANNOTATION")
load("//bazel/cargo/crates:indexmap-1.9.3.bzl", indexmap_1_9_3 = "ANNOTATION")
load("//bazel/cargo/crates:libc.bzl", libc = "ANNOTATION")
load("//bazel/cargo/crates:libudev-sys.bzl", libudev_sys = "ANNOTATION")
load("//bazel/cargo/crates:num-integer-0.1.45.bzl", num_integer_0_1_45 = "ANNOTATION")
load("//bazel/cargo/crates:num-rational.bzl", num_rational = "ANNOTATION")
load("//bazel/cargo/crates:num-traits.bzl", num_traits = "ANNOTATION")
load("//bazel/cargo/crates:objc-sys.bzl", objc_sys = "ANNOTATION")
load("//bazel/cargo/crates:proc-macro2.bzl", proc_macro2 = "ANNOTATION")
load("//bazel/cargo/crates:syn.bzl", syn = "ANNOTATION")
load("//bazel/cargo/crates:winapi.bzl", winapi = "ANNOTATION")
load("//bazel/cargo/crates:windows_x86_64_msvc-0.42.2.bzl", windows_x86_64_msvc_0_42_2 = "ANNOTATION")
load("//bazel/cargo/crates:windows_x86_64_msvc-0.48.5.bzl", windows_x86_64_msvc_0_48_5 = "ANNOTATION")
load("//bazel/cargo/crates:winit.bzl", winit = "ANNOTATION")
load("//bazel/cargo/crates:x11-dl.bzl", x11_dl = "ANNOTATION")

PACKAGES = {
    "bevy": crate.spec(
        version = "0.12.0",
    ),
}

ANNOTATIONS = {
    "alsa-sys": [alsa_sys],
    "blake3": [blake3],
    "coreaudio-sys": [coreaudio_sys],
    "gilrs": [gilrs],
    "indexmap": [indexmap_1_9_3],
    "libc": [libc],
    "libudev-sys": [libudev_sys],
    "num-integer": [num_integer_0_1_45],
    "num-rational": [num_rational],
    "num-traits": [num_traits],
    "objc-sys": [objc_sys],
    "proc-macro2": [proc_macro2],
    "syn": [syn],
    "winapi": [winapi],
    "windows_x86_64_msvc": [windows_x86_64_msvc_0_42_2, windows_x86_64_msvc_0_48_5],
    "winit": [winit],
    "x11-dl": [x11_dl],
}
