use bevy::prelude::*;

#[no_mangle]
fn android_main(android_app: bevy::winit::AndroidApp) {
    let _ = bevy::winit::ANDROID_APP.set(android_app);
    App::new().add_plugins(DefaultPlugins).run();
}
