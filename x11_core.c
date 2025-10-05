#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <X11/Xlib.h>
#include <X11/extensions/Xdbe.h>

#include <unistd.h>

// #define WIDTH 800
// #define HEIGHT 600
#define FPS 60
#define RECT_WIDTH 300
#define RECT_HEIGHT 300

#define DB_NONE   0
#define DB_XDBE   1
#define DB_PIXMAP 2
#define DB_XIMAGE 3


typedef struct {
  Display *display;
  Window window;
  GC gc;
  uint32_t *pixels;
  XImage *image;
} DB;

void db_init(DB *db, Display *display, Window window);
void db_clear(DB *db);
void db_fill_rect(DB *db, int x0, int y0, unsigned int w, unsigned int h);
void db_swap_buffers(DB *db);


DB db = {0};
Display *display;
Window window;
Atom wm_delete_window;

int rect_x = 10;
int rect_y = 10;

int rect_dx = -6;
int rect_dy = -6;

int width;
int height;

uint32_t* core_init( int _width, int _height )
{
  width  = _width;
  height = _height;

  display = XOpenDisplay(NULL);
  if (display == NULL) {
    fprintf(stderr, "ERROR: could not open the default display\n");
    exit(1);
    return NULL;
  }

  window = XCreateSimpleWindow(
    display,
    XDefaultRootWindow(display),
    0, 0,
    width, height,
    0,
    0,
    0);

  db_init(&db, display, window);

  XStoreName(display, window, "DB Implementation: cock");

  wm_delete_window = XInternAtom(display, "WM_DELETE_WINDOW", False);
  XSetWMProtocols(display, window, &wm_delete_window, 1);

  XSelectInput(display, window, KeyPressMask);

  XMapWindow(display, window);

  return db.pixels;
}
void core_window_set_title( char* str )
{
  XStoreName(display, window, str);
}

int core_update_pre()
{
  int quit = 0;
  // while (!quit) {
  while (XPending(display) > 0) {
    XEvent event = {0};
    XNextEvent(display, &event);
    switch (event.type) {
      case KeyPress: {
        switch (XLookupKeysym(&event.xkey, 0)) {
          case 'q':
            quit = 1;
            break;
          default:
            {}
        }
      } break;
      case ClientMessage: {
        if ((Atom) event.xclient.data.l[0] == wm_delete_window) {
          quit = 1;
        }
      }
        break;
    }
  }

  db_clear(&db);
  // db_fill_rect(&db, rect_x, rect_y, RECT_WIDTH, RECT_HEIGHT);

  return quit;
}
void core_update_post()
{
  db_swap_buffers(&db);

  // int rect_nx = rect_x + rect_dx;
  // if (rect_nx <= 0 || rect_nx + RECT_WIDTH >= width) {
  //   rect_dx *= -1;
  // } else {
  //   rect_x = rect_nx;
  // }
  //
  // int rect_ny = rect_y + rect_dy;
  // if (rect_ny <= 0 || rect_ny + RECT_HEIGHT >= height) {
  //   rect_dy *= -1;
  // } else {
  //   rect_y = rect_ny;
  // }

  usleep(1000*1000/FPS);
}
void core_cleanup()
{
  XCloseDisplay(display);
}

// --- db_ximage.c ---


void db_init(DB *db, Display *display, Window window)
{
  db->display = display;
  db->window = window;
  db->gc = XCreateGC(display, window, 0, NULL);
  db->pixels = malloc(sizeof(uint32_t) * width * height);

  XWindowAttributes wa = {0};
  XGetWindowAttributes(display, window, &wa);

  db->image = XCreateImage(display,
                           wa.visual,
                           wa.depth,
                           ZPixmap,
                           0,
                           (char*) db->pixels,
                           width, height,
                           32,
                           width * sizeof(uint32_t));
}

void db_clear(DB *db)
{
  memset(db->pixels, 0, sizeof(uint32_t) * width * height);
}

void db_fill_rect(DB *db, int x0, int y0, unsigned int w, unsigned int h)
{
  for (unsigned int dx = 0; dx < w; ++dx) 
  {
    for (unsigned int dy = 0; dy < h; ++dy) 
    {
      int x = x0 + dx;
      int y = y0 + dy;

      if (0 <= x && x < width &&
        0 <= y && y < height) 
      {
        db->pixels[y*width + x] = 0xFF0000;
      }
    }
  }
}

void db_swap_buffers(DB *db)
{
  XPutImage(db->display, db->window, db->gc, db->image, 0, 0, 0, 0, width, height);
}
