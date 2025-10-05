package core

import        "core:c"
import        "core:fmt"
import linalg "core:math/linalg/glsl"
import        "vendor:glfw"

width  := 800
height := 480

rect_x := 10
rect_y := 10
rect_dx := -6
rect_dy := -6
rect_width  := 75
rect_height := 75

main :: proc()
{
  pixels : [^]c.uint32_t = init( c.int(width), c.int(height) )
  data_init()

	// if !bool(glfw.Init()) 
  //  {
	// 	fmt.eprintln("GLFW has failed to load.")
	// 	return
	// }
  // input_init()

  should_quit := 0

  for should_quit == 0
  {
    data_pre_updated()
    // @TODO: calc delta_t and fps
    //        then display that in window title
    should_quit = int( update_pre() )
		// glfw.PollEvents()


    rect_nx := rect_x + rect_dx;
    if rect_nx <= 0 || rect_nx + rect_width >= width 
    {
      rect_dx *= -1;
    } 
    else 
    {
      rect_x = rect_nx;
    }

    rect_ny := rect_y + rect_dy;
    if rect_ny <= 0 || rect_ny + rect_height >= height 
    {
      rect_dy *= -1;
    } 
    else 
    {
      rect_y = rect_ny;
    }
    fill_rect( pixels, rect_x, rect_y, rect_width, rect_height )

    // if input.key_states[Key.ESCAPE].down
    // {
    //   should_quit = 1
    // }

    // input_update()
    update_post()
  }
  
  cleanup()
}

fill_rect :: proc(pixels: [^]c.uint32_t, x0, y0: int, w, h: int)
{
  for dx := 0; dx < w; dx += 1 
  {
    for dy := 0; dy < h; dy += 1
    {
      x := x0 + dx;
      y := y0 + dy;

      if (0 <= x && x < width &&
        0 <= y && y < height) 
      {
        pixels[y*width + x] = 0xFF00FF; // 0xFF0000;
      }
      else
      {
        pixels[y*width + x] = u32( linalg.distance( linalg.vec2{f32(dx), f32(dy)}, linalg.vec2{f32(x), f32(y)} ) * f32(0x00FFFF) ); // 0xFF0000;
      }
    }
  }
}
