""" Crate Annotation for num-traits """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    rustc_flags = [
        "--cfg=has_to_int_unchecked",
        "--cfg=has_reverse_bits",
        "--cfg=has_leading_trailing_ones",
        "--cfg=has_div_euclid",
        "--cfg=has_copysign",
        "--cfg=has_is_subnormal",
        "--cfg=has_total_cmp",
        "--cfg=has_int_to_from_bytes",
        "--cfg=has_float_to_from_bytes",
    ],
)
