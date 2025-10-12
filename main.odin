package core

import        "core:c"
import        "core:os"
import        "core:fmt"
import m      "core:math"
import linalg "core:math/linalg/glsl"
import        "vendor:glfw"
import gl     "vendor:OpenGL"

SPALL_ENABLED :: #config(SPALL_ENABLED, false)

width  := 800 * 2
height := 480 * 2
pixels      : []c.uint8_t
pixels_data : [^]c.uint8_t
pixels_len  : int

when ODIN_OS == .Windows{
  pixels_handle : u32
}

rect_x : f32 = 0
rect_y : f32 = 0
rect_dx := -6
rect_dy := -6
rect_width  := 75
rect_height := 75

main :: proc()
{
  when ODIN_OS == .Linux {
    pixels = x11_init( c.int(width), c.int(height) )
    pixels_len = width * height
  } else {
    window_create( 0.5, 0.5, 0.1, 0.1, "title", Window_Type.MINIMIZED, true )
    width  = data.window_width 
    height = data.window_height
    gl.Viewport( 0, 0, i32(width), i32(height) )
    fmt.println( "texture width:", width, ", height:", height )

    pixels_len = width * height // @UNSURE: width*2 * height*2
    pixels = make( []c.uint8_t, pixels_len * 4 )
    pixels_data = raw_data(pixels)
    for i := 0; i < pixels_len; i += 4
    {
      if (i * 4) % 20 < 10 
      {
        pixels[i +0] = 0xFF
        pixels[i +1] = 0x00
        pixels[i +2] = 0xFF
        pixels[i +3] = 0xFF
      }
      else
      {
        pixels[i +0] = 0x00
        pixels[i +1] = 0xFF
        pixels[i +2] = 0xFF
        pixels[i +3] = 0xFF
      }
    }

    gl.GenTextures( 1, &pixels_handle )
    gl.BindTexture( gl.TEXTURE_2D, pixels_handle )

    // Texture wrapping options.
    // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT )
    gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT )
    
    // Texture filtering options.
    gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
    gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR )

    // describe texture.
    gl.TexImage2D(
        gl.TEXTURE_2D,      // texture type
        0,                  // level of detail number (default = 0)
        gl.RGBA8,             // gl.RGBA, // texture format
        i32(width),         // width
        i32(height),        // height
        0,                  // border, must be 0
        gl.RGBA,            // gl.RGB, // pixel data format
        gl.UNSIGNED_BYTE,   // data type of pixel data
        pixels_data,             // image data
    )
    opengl_check_errors()
    // fmt.println( "gl.MAX_TEXTURE_SIZE:", gl.MAX_TEXTURE_SIZE, ", width:", width, ",height:", height )
    
    gl.Disable(gl.DEPTH_TEST);

    // data.basic_shader = shader_make( #load( "assets/shaders/basic.vert", string ), 
    //                                  #load( "assets/shaders/basic.frag", string ), "basic_shader" )
    data.quad_shader  = shader_make( #load( "assets/shaders/quad.vert", string ), 
                                     #load( "assets/shaders/quad.frag", string ), "quad_shader" )
    input_init()
  }
  data_init()

  should_quit := 0

  for should_quit == 0
  {
    data_pre_updated()
    // @TODO: calc delta_t and fps
    //        then display that in window title
    when ODIN_OS == .Linux {
      should_quit = int( x11_update_pre() )
    } else {
		  glfw.PollEvents()

      if input.key_states[Key.TAB].pressed { data.wireframe_mode_enabled = !data.wireframe_mode_enabled }

      if input.mouse_button_states[Mouse_Button.LEFT].down
      {
        rect_x += input.mouse_delta_x * 0.0015 
        rect_y += input.mouse_delta_y * 0.0015 
      }

      if input.key_states[Key.SPACE].down
      {
        rect_x = 0
        rect_y = 0
      }
    }

    draw()

    when ODIN_OS == .Linux {
    } else {

      upload_new_pixels_to_gpu()

      gl.ClearColor( 1.0, 1.0, 1.0, 1.0 )  //clear screen by white pixel
      gl.Clear( gl.COLOR_BUFFER_BIT )
      
      if data.wireframe_mode_enabled
	    { 
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE) 
        gl.LineWidth( 3 )
      }
	    else
	    { gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL) }
                                                                              
      shader_use( data.quad_shader )
      shader_act_set_vec2_f( "pos", rect_x, rect_y )
      shader_act_set_vec2_f( "scl", 1, 1 )
      shader_act_set_vec3_f( "tint", 1, 1, 1 )
      
      gl.ActiveTexture( gl.TEXTURE0 )
      gl.BindTexture( gl.TEXTURE_2D, pixels_handle )
      shader_act_set_i32( "tex", 0 )

      gl.BindVertexArray( data.quad_vao )
      gl.DrawArrays( gl.TRIANGLES, 0, 6 )

    }

    when ODIN_OS == .Linux {
      x11_update_post()
    } else {

      if ( input.key_states[Key.ESCAPE].pressed )
      { should_quit = 1; break }

      input_update()

      if should_quit != 0 || glfw.WindowShouldClose( data.window )
      { should_quit = 1; break }

      // check opengl errors
      opengl_check_errors()
      
      glfw.SwapBuffers( data.window ) //swap buffer  
    }
  }
  
  when ODIN_OS == .Linux { x11_cleanup() }
}

upload_new_pixels_to_gpu :: proc()
{
  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_2D, pixels_handle )
  gl.TexSubImage2D( gl.TEXTURE_2D, 0, 0, 0, i32(width), i32(height), gl.RGBA, gl.UNSIGNED_BYTE, pixels_data )
  
  // gl.Clear() basically
  for i := 0; i < pixels_len; i += 4
  {
    pixels[i +0] = 0xFF
    pixels[i +1] = 0x00
    pixels[i +2] = 0xFF
    pixels[i +3] = 0xFF
  }

  opengl_check_errors()
}

resize_texture :: proc( width, height: int )
{
  gl.DeleteTextures( 1, &pixels_handle )

  gl.GenTextures( 1, &pixels_handle )
  gl.BindTexture( gl.TEXTURE_2D, pixels_handle )
  gl.ActiveTexture( gl.TEXTURE0 )

  // Texture wrapping options.
  // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  // gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT )
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT )
  
  // Texture filtering options.
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR )
  gl.TexParameteri( gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR )

  // describe texture.
  gl.TexImage2D(
      gl.TEXTURE_2D,      // texture type
      0,                  // level of detail number (default = 0)
      gl.RGB,             // gl.RGBA, // texture format
      i32(width),         // width
      i32(height),        // height
      0,                  // border, must be 0
      gl.RGBA,            // gl.RGB, // pixel data format
      gl.UNSIGNED_BYTE,   // data type of pixel data
      pixels,             // image data
  )

  opengl_check_errors()
}


draw :: proc()
{
  fill_bg( pixels )

  // rect_nx := rect_x + rect_dx;
  // if rect_nx <= 0 || rect_nx + rect_width >= width 
  // {
  //   rect_dx *= -1;
  // } 
  // else 
  // {
  //   rect_x = rect_nx;
  // }

  // rect_ny := rect_y + rect_dy;
  // if rect_ny <= 0 || rect_ny + rect_height >= height 
  // {
  //   rect_dy *= -1;
  // } 
  // else 
  // {
  //   rect_y = rect_ny;
  // }
  // fill_rect( pixels, rect_x, rect_y, rect_width, rect_height )

  // fill_circle( pixels, width / 2, height / 2, 100 )
  // fill_rect( pixels, width / 2, height / 2, 10, 10 )
}

fill_bg :: proc( pixels: [^]c.uint8_t )
{
  // for x in 0..<width * 2
  // {
  //   for y in 0..<height * 2
  //   {
  //     x0 := f32(x) / f32(width)
  //     y0 := f32(y) / f32(height)
  //     // pixels[y*width + x] = ( u32( x0 * 0xFF ) << 16 ) +  // red channel
  //     //                       ( u32( y0 * 0xFF ) << 8 )     // green channel
  //     pixels[y*width + x * 4 + 0] = u8( x0 * 0xFF )
  //     pixels[y*width + x * 4 + 1] = u8( y0 * 0xFF )
  //   }
  // }

  for i := 0; i < pixels_len; i += 4
  {
    x0 := (i / 4) % width
    y0 := (i / 4) / width


    pixels[i +0] = 0x00
    pixels[i +1] = c.uint8_t( f32(0xFF) * (f32(x0) / f32(width)) )
    pixels[i +2] = c.uint8_t( f32(0xFF) * (f32(y0) / f32(height)) )
    pixels[i +3] = 0xFF
  }
}
fill_rect :: proc(pixels: [^]c.uint8_t, x0, y0: int, w, h: int)
{
  for dx := 0; dx < w; dx += 1 
  {
    for dy := 0; dy < h; dy += 1
    {
      x := x0 + dx;
      y := y0 + dy;
      

      // if (0 <= x && x < width &&
      //   0 <= y && y < height) 
      // {
      //   pixels[y*width + x] = 0xFF00FF; // 0xFF0000;
      // }

      // pixels[y*width + x] = u32( linalg.distance( linalg.vec2{f32(dx), f32(dy)}, linalg.vec2{f32(x), f32(y)} ) * f32(0x00FFFF) ); // 0xFF0000;
      // fmt.println( x, ",", y, "|", linalg.distance( linalg.vec2{f32(dx), f32(dy)}, linalg.vec2{f32(x), f32(y)} ) )
      dist := m.abs( f32(x0) - f32(dx) ) + m.abs( f32(y0) - f32(dy) )
      dist /= f32(width)
      // fmt.println( x0, ",", y0, "|", dx, ",", dy, "| ->", dist )
      // pixels[y*width + x] = u32( dist * 0xFF0000 ) << 16
      pixels[y*width + x * 4] = u8( dist * 0xFF0000 )

      // pixels[y*width + x] = u32( x + ( y * 0x00FF00 ) )

      x_perc := 1 - f32(x) / f32(width)
      y_perc := 1 - f32(y) / f32(height)
      
      // pixels[y*width + x] = u32( ( x_perc + y_perc ) * 0.5 * 0xFF )
      pixels[y*width + x * 4 + 2] = u8( ( x_perc + y_perc ) * 0.5 * 0xFF )

    }
  }
  // os.exit(0)
}

fill_circle :: proc(pixels: [^]c.uint8_t, x0, y0: int, radius: int)
{
  dist_max : f32 = 0.0
  for dx := 0; dx < radius; dx += 1 
  {
    for dy := 0; dy < radius; dy += 1
    {
      x := x0 + dx
      y := y0 + dy
      
      dist := linalg.distance( linalg.vec2{f32(x), f32(y)}, linalg.vec2{f32(x0), f32(y0)} )
      // dist_x := m.abs(f32(x) - f32(x0))
      // dist_y := m.abs(f32(y) - f32(y0))
      // fmt.println( "dist x:", dist_x, ", y:", dist_y )
      // fmt.println( "dist:", dist )
      if dist > dist_max { dist_max = dist }
      if dist <= f32(radius)
      {
        // pixels[y*width + x] = 0xFF00FF // 0xFF0000
        pixels[y*width + x * 4 +0] = 0xFF // 0xFF0000
        pixels[y*width + x * 4 +1] = 0x00 // 0xFF0000
        pixels[y*width + x * 4 +2] = 0xFF // 0xFF0000
        // fmt.println( "dist:", dist )
      }
      // pixels[y*width + x] = u32( m.clamp(dist / f32(radius), 0, 1) /*  * 0xFF0000 */ ) // 0xFF0000
    }
  }
  // fmt.println( "dist_max:", dist_max )
  // os.exit(0)
}
