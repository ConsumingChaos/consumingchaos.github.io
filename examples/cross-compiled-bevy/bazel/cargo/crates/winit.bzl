""" Crate Annotation for winit """

load("@rules_rust//crate_universe:defs.bzl", "crate")

ANNOTATION = crate.annotation(
    rustc_flags = crate.select(
        [],
        {
            "aarch64-apple-darwin": [
                "--cfg=macos_platform",
                "--cfg=apple",
            ],
            "aarch64-apple-ios": [
                "--cfg=ios_platform",
                "--cfg=apple",
            ],
            "aarch64-linux-android": [
                "--cfg=android_platform",
            ],
            "aarch64-unknown-linux-gnu": [
                "--cfg=free_unix",
                "--cfg=x11_platform",
            ],
            "wasm32-unknown-unknown": [],
            "wasm32-wasi": [],
            "x86_64-apple-darwin": [
                "--cfg=macos_platform",
                "--cfg=apple",
            ],
            "x86_64-pc-windows-msvc": [
                "--cfg=windows_platform",
            ],
            "x86_64-unknown-linux-gnu": [
                "--cfg=free_unix",
                "--cfg=x11_platform",
            ],
        },
    ),
)
