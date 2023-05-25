use bevy::prelude::*;

fn main()
{
    App::new().add_plugins(DefaultPlugins).run();
}

#[no_mangle]
#[cfg(target_os = "android")]
fn android_main(android_app: bevy::winit::AndroidApp)
{
    let _ = bevy::winit::ANDROID_APP.set(android_app);
    main();
}

#[no_mangle]
#[cfg(target_os = "ios")]
extern "C" fn main_rs()
{
    main();
}
