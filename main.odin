package core

import        "core:c"
import        "core:os"
import        "core:fmt"
import m      "core:math"
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


    fill_bg( pixels )

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

    fill_circle( pixels, width / 2, height / 2, 100 )
    fill_rect( pixels, width / 2, height / 2, 10, 10 )

    // if input.key_states[Key.ESCAPE].down
    // {
    //   should_quit = 1
    // }

    // input_update()
    update_post()
  }
  
  cleanup()
}

fill_bg :: proc( pixels: [^]c.uint32_t )
{
  for x in 0..<width
  {
    for y in 0..<height
    {
      x0 := f32(x) / f32(width)
      y0 := f32(y) / f32(height)
      pixels[y*width + x] = ( u32( x0 * 0xFF ) << 16 ) +  // red channel
                            ( u32( y0 * 0xFF ) << 8 )     // green channel
    }
  }
}
fill_rect :: proc(pixels: [^]c.uint32_t, x0, y0: int, w, h: int)
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
      pixels[y*width + x] = u32( dist * 0xFF0000 ) << 16

      // pixels[y*width + x] = u32( x + ( y * 0x00FF00 ) )

      x_perc := 1 - f32(x) / f32(width)
      y_perc := 1 - f32(y) / f32(height)
      
      pixels[y*width + x] = u32( ( x_perc + y_perc ) * 0.5 * 0xFF )

    }
  }
  // os.exit(0)
}

fill_circle :: proc(pixels: [^]c.uint32_t, x0, y0: int, radius: int)
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
        pixels[y*width + x] = 0xFF00FF // 0xFF0000
        // fmt.println( "dist:", dist )
      }
      pixels[y*width + x] = u32( m.clamp(dist / f32(radius), 0, 1) /*  * 0xFF0000 */ ) // 0xFF0000
    }
  }
  // fmt.println( "dist_max:", dist_max )
  // os.exit(0)
}
