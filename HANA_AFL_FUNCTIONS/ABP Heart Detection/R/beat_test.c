#include <stdio.h>
#include <float.h>
#include <stdlib.h>
#include <math.h>
#include "beat_detection.h"

int main(){
	char ch;
        FILE *fp;
        fp = fopen("abp_test_dat_9000.txt","r");

        int len=0;
        double signal[10000];
        while( (ch = fgetc(fp)) != EOF){
                char digit[256];
                int d = 0;
                while(ch != '\n'){
                        digit[d]=ch;
                        ch = fgetc(fp);
                        d++;
                }
                signal[len] = atof(digit);
                len++;

        }
        fclose(fp);

	int i;
	double *onset_point = (double*)malloc(len/150* sizeof(double));
	int *n = &len;
	pipeline_beat_detection(signal,n,onset_point);
//	for(i=0;i<160;i++) printf("%f,",onset_point[i]);
	return 0;

}
