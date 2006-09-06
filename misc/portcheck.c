/* from msachs */
/* exit indicates if Aqua GUI is available */

/* gcc -framework CoreFoundation -o portcheck portcheck.c */
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
        CFMessagePortRef port = NULL;
        CFMessagePortContext context = {0, NULL, NULL, NULL, NULL};

        port = CFMessagePortCreateLocal(NULL, CFSTR("hello-port"), NULL, &context, NULL);
        printf("%x\n", port);

        if(port == NULL)
                return 1;
        else {
                CFRelease(port);
                return 0;
        }
}

