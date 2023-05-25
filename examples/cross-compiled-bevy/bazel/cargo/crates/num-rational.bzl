""" Crate Annotation for num-rational """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    rustc_flags = [
        "--cfg=has_int_exp_fmt",
    ],
)
