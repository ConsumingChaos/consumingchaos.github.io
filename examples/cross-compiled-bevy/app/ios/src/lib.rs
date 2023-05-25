use bevy::prelude::*;

#[no_mangle]
extern "C" fn main_rs() {
    App::new().add_plugins(DefaultPlugins).run();
}
