package core

import linalg "core:math/linalg/glsl"
import str    "core:strings"
import        "core:time"
import        "core:fmt"
import        "vendor:glfw"

// "typedefs" for linalg/glsl package
vec2 :: linalg.vec2
vec3 :: linalg.vec3
vec4 :: linalg.vec4
mat3 :: linalg.mat3
mat4 :: linalg.mat4

Window_Type :: enum { MINIMIZED, MAXIMIZED, FULLSCREEN };

texture_t :: struct
{
  handle   : u32,
  width    : int,
  height   : int,
  channels : int,

  name   : string,  // @TODO: only needed in debug mode
}

material_t :: struct
{
  albedo_idx       : int,
  roughness_idx    : int,
  metallic_idx     : int,
  normal_idx       : int,
  emissive_idx     : int,

  uv_tile          : linalg.vec2,
  uv_offs          : linalg.vec2,

  tint             : linalg.vec3,
  roughness_f      : f32,
  metallic_f       : f32,
  emissive_f       : f32,

  name             : string,  // @TODO: only needed in debug mode
}

mesh_t :: struct
{
  vao          : u32,
  vbo          : u32,
  vertices_len : int, 
  indices_len  : int, 

  name         : string  // @TODO: only needed in debug mode
}

entity_t :: struct
{
  dead             : bool,

  pos, rot, scl    : linalg.vec3,
  
  mesh_idx         : int,

  mat_idx          : int,

  model, inv_model : linalg.mat4,

}

data_t :: struct
{
  delta_t_real      : f32,
  delta_t           : f32,
  total_t           : f32,
  cur_fps           : f32,
  time_scale        : f32,
  delta_t_stopwatch : time.Stopwatch,

  window                 : glfw.WindowHandle,
  window_type            : Window_Type,
  window_width           : int,
  window_height          : int,
  monitor                : glfw.MonitorHandle,
  monitor_width          : int,
  monitor_height         : int,
  monitor_size_cm_width  : f32,
  monitor_size_cm_height : f32,
  monitor_dpi_width      : f32,
  monitor_dpi_height     : f32,
  monitor_ppi_width      : f32,
  monitor_ppi_height     : f32,
  vsync_enabled          : bool,

  wireframe_mode_enabled : bool,
  
  cam : struct
  {
    pos       : linalg.vec3,
    target    : linalg.vec3,
    pitch_rad : f32, 
    yaw_rad   : f32, 
    view_mat  : linalg.mat4,
    pers_mat  : linalg.mat4,
  },
}
// global struct holding most data about the game, except input
data : data_t =
{
  delta_t_real      = 0.0,
  delta_t           = 0.0,
  total_t           = 0.0,
  cur_fps           = 0.0,
  time_scale        = 1.0,
  
  wireframe_mode_enabled = false,

  cam = 
  {
    // pos       = { 0, 5, -6 },
    pos       = { 0,11.5, -12 },
    target    = {  0, 0, 0 },
    // pitch_rad = -0.4,
    // yaw_rad   = 14.2,
    pitch_rad = -0.78397244,
    yaw_rad   = 14.130187,
  },
}

data_init :: proc()
{
  time.stopwatch_start( &data.delta_t_stopwatch )
}

data_pre_updated :: proc()
{
  @(static) first_frame := true
  // ---- time ----
	// data.delta_t_real = f32(glfw.GetTime()) - data.total_t
	// data.total_t      = f32(glfw.GetTime())
  data.delta_t_real = f32( time.duration_seconds( time.stopwatch_duration( data.delta_t_stopwatch ) ) )
  time.stopwatch_reset( &data.delta_t_stopwatch )
  time.stopwatch_start( &data.delta_t_stopwatch )
  data.cur_fps      = 1 / data.delta_t_real
  if ( first_frame ) 
  { data.delta_t_real = 0.016; first_frame = false; } // otherwise dt first frame is like 5 seconds
  data.delta_t = data.delta_t_real * data.time_scale
  
  window_set_title( 
    str.clone_to_cstring( 
      fmt.tprint( "amazing title | fps: ", data.cur_fps ), 
      context.temp_allocator ) 
  )
  
}

// data_entity_remove :: proc( idx: int )
// {
//   assert( !data.entity_arr[idx].dead, "tried removing dead entity" )
//   assert( idx >= 0 && idx < len(data.entity_arr), "invalid entity idx" )
// 
//   data.entity_arr[idx].dead = true
//   append( &data.entity_dead_idx_arr, idx )
// }
// data_entity_add :: proc( e: entity_t ) -> ( idx: int )
// {
//   idx = -1
// 
//   if len(data.entity_dead_idx_arr) > 0
//   {
//     idx = pop(&data.entity_dead_idx_arr)
//     data.entity_arr[idx] = e
//   }
//   else
//   {
//     idx = len(data.entity_arr)
//     append( &data.entity_arr, e )
//   }
//   
//   return idx
// }

