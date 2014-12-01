#include<math.h>
#include<stdbool.h>
#include<stdlib.h>
#include<limits.h>
#include<stdio.h>
#include "data_cleansing.h"
#define min_sequence 250
#define filter_size 100
#define pi 3.14159
#define sigma 10
#define exp 2.71828

// cleansing noisy data
// step 1: #sigma filter to original blood pressure signal
// step 2: calculate differential in the original blood pressure signal
//	   and also apply #sigma filter to the differentiated signal 
// step 3: continuity check, remove too short sequences remained in the signal

// WARNING: the times of sigmas are hard coded for setting threshold
void data_cleansing(double* amplitude, int n){
	
	gaussianFilter(amplitude,n);

	bool *tag = (bool*)malloc(n * sizeof(bool));
	for(int i =0;i<n;i++) tag[i]=true;

	for(int i = 0;i<n;i++){
		if(amplitude[i] <= 0) {
		tag[i] = false;
		}
	}
	

	double *slope = (double*) malloc(n*sizeof(amplitude));
        slope[0]= 0;

	for(int i =0;i<n;i++){
                if(tag[i]) {
                        slope[i] = abs(amplitude[i]-amplitude[i-1]);
                        }
        }

	
	int count = 0;
	double sum = 0.0, slope_sum = 0.0, mean = 0.0, slope_mean = 0.0, cov = 0.0, slope_cov = 0.0;
	
	for(int i =0;i<n;i++){
		if( tag[i] ){
			count++;
			sum += amplitude[i];
			slope_sum = slope[i];
		}
	}
	mean = (double) sum/count;
	slope_mean = (double) slope_sum/count;		
	
	double x_mean=0.0, slope_x_mean = 0.0;
	for( int i =0; i<n;i++){
		if( tag[i] ){
			x_mean += pow((amplitude[i]-mean),2);
			slope_x_mean += pow((slope[i] - mean),2);
		}
	}
	cov = sqrt((double)x_mean/count);
	slope_cov = sqrt((double)slope_x_mean/count);
	
	// filter data by threshold
	for( int i = 0 ; i < n;i++){
		if(tag[i] && ( amplitude[i] < mean-1*cov ||amplitude[i] > mean + 2*cov) && ( slope[i] < slope_mean || slope[i] > slope_mean + 0.5 * slope_cov))
			tag[i] = false;
	}
	int i = 0;
	while(	i < n){
		if(tag[i]){
			count =0;
			int start = i;
			while( i < n && tag[i]){
				count++;
				i++;
			}
			if( count < min_sequence ){
				for( int j = start; j<= start+count; j++){
					tag[j]= false;
				}
			}
		}
		else i++;
	}

	for(int i =0;i<n;i++){
		if(!tag[i]) amplitude[i] = INT_MIN;
	}	
}


void gaussianFilter( double *amplitude, int n){
	double *filtered_amp = (double*)malloc(n * sizeof(double));
        double *filter = (double*)malloc( filter_size * sizeof(double));
        for( int i =0;i<filter_size;i++){
                filter[i] = 1.0 / (sqrt(2.0 * pi) * sigma) * pow(exp,pow((double)(i-filter_size/2)/sigma,2));
        }
        for(int i = 0;i< n;i++){
                for(int j =0;j<filter_size;j++){
                        filtered_amp[i] += (i - filter_size/2 + j)<0 ? 0:amplitude[i-filter_size + j] * filter[j];
                }
        }
	amplitude = filtered_amp;
}
