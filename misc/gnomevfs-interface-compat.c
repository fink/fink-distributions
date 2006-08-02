/*
  Symbols were removed from the gnome-vfs interface between version
  2.15.2 and 2.15.3: but the libtool flags that indicate the ABI
  breakage were not set. We therefore must re-add the missing symbols
  in order to have a consistent ABI for the library install_name.

  The functions that were removed were added to libbonobo starting in
  version 2.15.0, so these wrapper functions load that library at
  runtime and import those symbols.

  Compile with
    -DLIBBONOBO_PATH=\""/sw/lib/libbonobo-activation-2.0.dylib"\"
  or whatever shared library provides the symbols now
*/

#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>

#include <glib/glist.h>
#include <bonobo-activation/bonobo-activation-server-info.h>

void gnome_vfs_mime_component_list_free (GList *list) {
  static void (*p)(GList*) = NULL;

  if (NULL == p) {
    char *libbonobo_dl = NULL;
    libbonobo_dl = dlopen(LIBBONOBO_PATH,RTLD_LAZY);
    if (NULL == libbonobo_dl) {
      printf("interface-compat: %s\n", dlerror());
      exit(1);
    }
    p = dlsym(libbonobo_dl, __func__);
    if (NULL == p) {
      printf("interface-compat: %s: %s\n", LIBBONOBO_PATH, dlerror());
      exit(1);
    }
  }

  return p(list);
}

Bonobo_ServerInfo * gnome_vfs_mime_get_default_component (const char *mime_type) {
  static void* (*p)(const char*) = NULL;

  if (NULL == p) {
    char *libbonobo_dl = NULL;
    libbonobo_dl = dlopen(LIBBONOBO_PATH,RTLD_LAZY);
    if (NULL == libbonobo_dl) {
      printf("interface-compat: %s\n", dlerror());
      exit(1);
    }
    p = dlsym(libbonobo_dl,__func__);
    if (NULL == p) {
      printf("interface-compat: %s: %s\n", LIBBONOBO_PATH, dlerror());
      exit(1);
    }
  }

  return p(mime_type);
}

GList* gnome_vfs_mime_get_all_components (const char *mime_type) {
  static void* (*p)(const char*) = NULL;

  if (NULL == p) {
    char *libbonobo_dl = NULL;
    libbonobo_dl = dlopen(LIBBONOBO_PATH,RTLD_LAZY);
    if (NULL == libbonobo_dl) {
      printf("interface-compat: %s\n", dlerror());
      exit(1);
    }
    p = dlsym(libbonobo_dl,__func__);
    if (NULL == p) {
      printf("interface-compat: %s: %s\n", LIBBONOBO_PATH, dlerror());
      exit(1);
    }
  }

  return p(mime_type);
}
