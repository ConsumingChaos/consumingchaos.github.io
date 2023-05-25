""" Crate Annotation for objc-sys """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    deps = [
        "@//bazel/platforms/apple:objc",
    ],
    rustc_flags = [
        "--cfg=apple",
        "--cfg=apple_new",
    ],
)
