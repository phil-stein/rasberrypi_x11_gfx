package core

import     "core:os"
import     "core:fmt"
import gl  "vendor:OpenGL"

opengl_check_errors :: #force_inline proc()
{
  err := gl.NO_ERROR
  count := 0 
  err = int(gl.GetError())
  for gl.GetError() != gl.NO_ERROR 
  { 
    fmt.printfln( "[OpenGL-ERROR] %v", err )
    count += 1
    err = int(gl.GetError())
  }
  if count > 0 
  { 
    fmt.printf("  -> had %d opengl error%s\n", count, count > 1 ? "s" : "")
    os.exit( 1 ) 
  }
}
