#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
typedef union{
    float f;
    uint32_t b;
} f2b;
int main(){
    FILE *test;
    char str[256];
    f2b a, b, res;
    unsigned int mode;
    int n;
    printf("Enter testfile path (.test): ");
    scanf("%s",str);
    test = fopen(str,"w");
    if(test == NULL){
        printf("\nError in opening file.");
        return 0;
    }
    printf("\nNumber of test cases: ");
    scanf("%d",&n);
    fprintf(test,"%d\n",n);
    for(int i = 0;i < n;i++){
        printf("\nOperand A: ");
        scanf("%f",&a.f);
        printf("\nOperand B: ");
        scanf("%f",&b.f);
        printf("\nMode: (0 => ADD, 1 => SUB): ");
        scanf("%u",&mode);
        res.f = mode ? a.f - b.f : a.f + b.f;
        fprintf(test,"%08x %08x %u %08x\n",a.b,b.b,mode,res.b);
    }
    fclose(test);
    return 0;
}