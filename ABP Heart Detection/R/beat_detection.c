#include <stdio.h>
#include <float.h>
#include <stdlib.h>
#include <math.h>
#include <limits.h>
#include "data_cleansing.h"
#include "beat_detection.h"
#define beat_window_size 16 //for slope sume 
#define baseline_samp_num 1250 // baseline in decision rule function to set threshold
#define threshold_scalar 0.6 
#define beat_detection_width  39

void pipeline_beat_detection(double *amplitude, int *len, double *onset_point){
	// cleansing data, set noisy signal to INT_MIN
	
	amplitude = data_cleansing(amplitude, *len);
	
	int count, start,onset_count = 0,current_onset_count;
	int i = 0;
	// detect meaningful sequence in the cleansed signal
	// and apply the cleansed signal to beat detection algorithm 
	while(i < *len){
		if(amplitude[i] == INT_MIN) i++;
		else{
			start = i;
			count = 0;
			while(i< *len && amplitude[i] != INT_MIN){
				count++;
				i++;
			}
			onset_point[onset_count] = -10000;
			current_onset_count = beat_detection(amplitude + start,count,onset_point + onset_count);
			// save detected beats 
			for( int i =0;i<current_onset_count;i++){
				onset_point[onset_count+i] += start;
			}
			onset_count +=current_onset_count;
			printf("%d,%d\n",start,count);
	
			
		}
	}
}

// beat detection algorithm continuous blood pressure signal 
int beat_detection( double *amplitude, int n, double *onset_point){
	double *ssf = slope_sum_function(amplitude,n);
	int count = decision_rule(ssf,n,onset_point);
	return count;
}

//calculate slope sum in a window(the size is #beat_window_size)
double* slope_sum_function(double* amplitude,int n){
	double *slope_sum = (double *)malloc(n * sizeof(amplitude));
	double _sum;
	int i;
	for(i =0;i<n;i++){
		int start = i - beat_window_size/2;
		int end = i + beat_window_size/2;
		int ii;
		_sum = 0.0;
		for(ii=start;ii<end;ii++){
			if( ii < 0 || ii > n) _sum = _sum + 0;
			else {
				double diff = amplitude[ii+1] - amplitude[ii];
				if(diff<0) _sum = _sum + 0;
				else _sum = _sum + diff;
			}	
		}
		slope_sum[i]=_sum;
	} 
	return slope_sum;
}

int decision_rule(double *slope_sum, int n, double *onset_point){
	double baseline_sum = 0.0;
	int onset_count =0;
	int i, ii, bii,local_i,onset_i;
	for(i = 0;i <(baseline_samp_num < n ? baseline_samp_num:n );i++)
		baseline_sum +=slope_sum[i];
	double threshold = 3 * (baseline_sum / (baseline_samp_num < n ? baseline_samp_num:n ));

	for(ii =0;ii<n;ii++){
		double v = slope_sum[ii];
		if(v>threshold * threshold_scalar){
			int beat_detection_range[beat_detection_width];
			int numbers_in_range = 0;
			int range_width = 0;
			double *local_value = (double *)malloc(n * sizeof(double));
			int *ind_order = (int *) malloc( n* sizeof(int));
			for( bii = 0; bii < beat_detection_width ; bii++) {
				int ind = ii-beat_detection_width/2+bii;
				if(ind >= 0 && ind < n){
					*(local_value+numbers_in_range) = slope_sum[ind];
					*(ind_order+numbers_in_range) = ind;
					numbers_in_range++;
				}
			}
			double max = -DBL_MAX, min = DBL_MAX;
			for(local_i = 0; local_i < numbers_in_range;local_i++){
				max = local_value[local_i] > max ? local_value[local_i] : max;
				min = local_value[local_i] <min ? local_value[local_i] : min;
			}
			if (( max - min ) > 8) {
	
				double onset_value = max * 0.01;
				for( onset_i=0;onset_i<numbers_in_range;onset_i++){
					if( slope_sum[ind_order[onset_i]] > onset_value){
						if(*onset_point == -10000) {//Hard coded!!
							*(onset_point+ onset_count) =  ind_order[onset_i];
							onset_count++;
						}
						else if( (ind_order[onset_i] - *(onset_point +onset_count- 1) > 85) ){
							*(onset_point + onset_count) = ind_order[onset_i];
							onset_count++;
						}						
					}
				}
			}
		}
	}
	return onset_count;
}

