""" Crate Annotation for libudev-sys """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    deps = [
        "@//bazel/platforms/linux:udev",
    ],
    rustc_flags = [
        "--cfg=hwdb",
    ],
)
