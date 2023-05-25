""" Crate Annotation for indexmap (1.9.3) """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    version = "1.9.3",
    rustc_flags = [
        "--cfg=has_std",
    ],
)
