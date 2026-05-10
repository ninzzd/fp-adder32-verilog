#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
typedef union {
    float f;
    uint32_t bin;
} f2b;
int main() {
    FILE *test;
    char line[256];
    f2b a, b, res;
    unsigned int mode;
    int n;
    test = fopen("test_vectors.csv", "w");
    if (test == NULL) {
        printf("Error opening file\n");
        return 1;
    }
    if (fgets(line, sizeof(line), stdin) == NULL) return 1;
    sscanf(line, "%d", &n);
    fprintf(test,"%d\n",n);
    for (int i = 0; i < n; i++) {

        if (fgets(line, sizeof(line), stdin) == NULL)
            break;

        if (sscanf(line, "%f,%f,%u", &a.f, &b.f, &mode) != 3) {
            printf("Invalid input format at line %d\n", i + 1);
            continue;
        }

        res.f = mode ? (a.f - b.f) : (a.f + b.f);

        fprintf(test, "%08x,%08x,%u,%08x\n",
                a.bin, b.bin, mode, res.bin);
    }

    fclose(test);
    return 0;
}