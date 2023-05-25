""" Crate Annotation for alsa-sys """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    deps = [
        "@//bazel/platforms/linux:alsa",
    ],
)
