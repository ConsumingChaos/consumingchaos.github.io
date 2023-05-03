load("@rules_rust//rust:defs.bzl", "rust_binary")

package(default_visibility = ["//visibility:public"])

rust_binary(
    name = "rust_binary",
    srcs = ["rust_binary.rs"],
    tags = ["platform_missing"],
    deps = [
        "//cc_library",
        "//rust_library",
    ],
)
