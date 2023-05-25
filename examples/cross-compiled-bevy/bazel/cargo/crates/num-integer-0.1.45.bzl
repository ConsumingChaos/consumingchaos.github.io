""" Crate Annotation for num-integer """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    version = "0.1.45",
    rustc_flags = [
        "--cfg=has_i128",
    ],
)
