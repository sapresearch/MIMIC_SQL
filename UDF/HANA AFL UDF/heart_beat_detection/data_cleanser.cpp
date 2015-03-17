#include<fstream>
#include<iterator>
#include<vector>
#include<cmath>
#include<climits>
#include<cstdlib>
#include<cstdio>
#include "data_cleanser.h"

using namespace std;
// constructor
data_cleanser:: data_cleanser(int seq, int filter_S ,double p = 3.14159, int s = 10, double e = 2.71828){
	min_sequence = seq;
	filter_size = filter_S;
	pi = p;
	sigma = s;
	exp = e;
}

// guassian filter 
vector<double> data_cleanser:: gaussianFilter(vector<double> &rawsignal){
	vector<double> signal(rawsignal.size());
	double *filter = (double*)malloc(filter_size * sizeof(double));
	double sum_ = 0.0;
	for( int i = 0;i<filter_size;i++){
		filter[i] = 1.0 / (sqrt(2.0 * pi) * sigma) * pow(exp,-pow((double)(i-filter_size/2)/sigma,2));
		sum_ += filter[i];
	}
	for(int i = 0;i< rawsignal.size();i++){
                for(int j =0;j<filter_size;j++){
					signal[i] += (i - filter_size/2 + j)<0 ? 0:rawsignal[i-filter_size + j] * filter[j];
				}
				signal[i] = signal[i] / sum_;
        }

	free(filter);
	return signal;

}

// cleansing noisy data: N sigma filters.
// step 1: #sigma filter to original blood pressure signal
// step 2: calculate differential in the original blood pressure signal
//	   and also apply #sigma filter to the differentiated signal 
// step 3: continuity check, remove too short sequences remained in the signal

// WARNING: the times of sigmas are hard coded for setting threshold

void data_cleanser::data_cleansing(vector<double> &signal){
	//smooth data with guassian filter
	signal = gaussianFilter(signal);
	
	// an associated tag array with the same length of input signal 
	// for indicating where the signal is not meaningful
	// true is meaningful, while false is not.
	bool *tag = (bool*)malloc( signal.size() * sizeof(bool));
	fill_n(tag, signal.size(), true);
	
	// set negative signal to false  
	for( int i = 0;i < signal.size();i++){
		if( signal[i]<=0) tag[i] = false;
	}
	
	// calculate differential in the original blood pressure signal
	vector< double > slope(signal.size(),0);
	for(int i=0;i<signal.size();i++){
		if( tag[i]) slope[i] = abs(signal[i] - signal[i-1]);
	}
	int count = 0;
	double sum = 0.0,
		slope_sum = 0.0,
		mean = 0.0,
		slope_mean = 0.0,
		cov = 0.0,
		slope_cov = 0.0;
	
	for( int i = 0;i<signal.size();i++){
		if(tag[i]){
			count++;
			sum += signal[i];
			slope_sum += slope[i];
		}
	}
	
	// calculate means and sigmas for both original signal and slope of signal
	mean = (double)sum/count;
	slope_mean = (double) slope_sum/count;
	
	double x_mean = 0.0, slope_x_mean = 0.0;
	for( int i = 0;i<signal.size();i++){
		if( tag[i]){
			x_mean += pow((signal[i] - mean),2);
			slope_x_mean += pow((slope[i] - slope_mean),2);
		}
	}
	
	cov = double(sqrt((double) x_mean/count));
	slope_cov = sqrt((double) slope_x_mean/count);
	
	// apply # sigma filter to both original signal and slope of signal
	 for( int i = 0 ; i < signal.size();i++){
                if(tag[i] && ( signal[i] < mean-1*cov ||signal[i] > mean + 2*cov) && ( slope[i] < slope_mean || slope[i] > slope_mean + 0.5 * slope_cov))
                        tag[i] = false;
        }
		
	int i =0;
	
	// step 3: continuity check, remove too short sequences remained in the signal
	while( i < signal.size()){
		if( tag[i]){
			count = 0;
			int start = i;
			while(i<signal.size() && tag[i]){
				count++;
				i++;
			}
			if( count< min_sequence){
				for( int j = start;j<= start+count;j++) tag[j] = false;
			}
		}
		else i++;
	}
	// set the unmeaningful signal to INT_MIN
	for( int i = 0; i< signal.size();i++){
		if( !tag[i]) signal[i] = INT_MIN;
	}
	free(tag);
}
