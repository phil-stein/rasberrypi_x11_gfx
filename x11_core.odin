package core

import "core:c"

when ODIN_OS == .Linux && ODIN_ARCH == .arm64 { foreign import lib "lib_x11_core.a" }
else { #panic( "not handled this architecture" ) }

foreign lib {

@(link_name="core_init")         init        :: proc(width, height: c.int) -> (pixels: [^]c.uint32_t) ---
@(link_name="core_update_pre")   update_pre  :: proc() -> (should_quit: c.int) ---
@(link_name="core_update_post")  update_post :: proc() ---
@(link_name="core_cleanup")      cleanup     :: proc() ---

@(link_name="core_window_set_title") window_set_title :: proc( str: cstring ) ---

}
