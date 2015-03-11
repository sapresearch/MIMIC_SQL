#include<fstream>
#include<iterator>


#include "beat_detector.h"

#include <climits>
#include <cfloat>
#include <hana/table.h>
#include <hana/numeric.h>
#include <hana/column.h>
#include <hana/logging.h>
#include <hana/task.h>
#include <vector>
#include "data_cleanser.h"

using namespace hana;
using namespace std;

// constructor
beat_detector:: beat_detector( int window, int baseline, double threshold, int detection_width){
	beat_window_size = window;
	baseline_samp_num = baseline;
	threshold_scalar = threshold ;
	beat_detection_width = detection_width;
}


// beat_detection(vector<double> &signal, int start, int count) implements 
// ABP heart detection algorithm in the paper
// paper : An Open-source Algorithm to Detect Onset of Arterial Blood Pressure Pulses
void beat_detector :: beat_detection(vector<double> &signal, int start, int count){
	vector<double> ssf = slope_sum_function(signal, start, count);
	



	decision_rule(ssf,start);
}

vector<double> beat_detector :: slope_sum_function(vector<double> &signal,int start, int count){
	vector<double> slope_sum(count);
	vector<double> sig(signal.begin()+start, signal.begin()+start+count);
	
	
	double _sum;
	int i;
	for( i = 0;i<sig.size();i++){
		int ss = i - beat_window_size/2;
		int end = i + beat_window_size/2;
		int ii;
		_sum = 0.0;
		for( ii = ss;ii<end;ii++){
			if( ii < 0 || ii >= sig.size()-1 ) _sum += 0;
			else{
				double diff = sig[ii+1]- sig[ii];
				if( diff < 0) _sum += 0;
				else _sum += diff;
			}
		}
		slope_sum[i] = _sum;
	}
	return slope_sum;
}

void beat_detector :: decision_rule(vector<double> &slope_sum, int start){
	double baseline_sum = 0.0;
	int i, ii, bii, local_i,onset_i;
	for(  i = 0;i<( baseline_samp_num < slope_sum.size() ? baseline_samp_num:slope_sum.size() ); i++ ){
		baseline_sum += slope_sum[i];
	}
	double threshold = 3 * (baseline_sum/ ( baseline_samp_num < slope_sum.size() ? baseline_samp_num:slope_sum.size() ) );
	for(ii = 0; ii< slope_sum.size();ii++){
		double v = slope_sum[ii];
		if( v > threshold * threshold_scalar){
			vector<int> beat_detection_range(beat_detection_width);
			int numbers_in_range = 0;
			int range_width = 0;
			vector<double> local_value(slope_sum.size());
			vector<int> ind_order(slope_sum.size());
			for( bii = 0; bii< beat_detection_width;bii++){
				int ind = ii - beat_detection_width/2 + bii;
				if( ind >= 0 && ind < slope_sum.size()){
					local_value[numbers_in_range] = slope_sum[ind];
					ind_order[numbers_in_range] = ind;
					numbers_in_range++;
				}
			}
			double max = -DBL_MAX, min = DBL_MAX;
			
			for(local_i = 0; local_i < numbers_in_range; local_i++){
				max = local_value[local_i] > max ? local_value[local_i] : max;
                min = local_value[local_i] <min ? local_value[local_i] : min;
			}
			
			if( ( max-min) > 8 ){
				double onset_value = max * 0.01;
				
				for( onset_i = 0; onset_i < numbers_in_range; onset_i++){
					if( slope_sum[ind_order[onset_i]] > onset_value){
						if( onset_point.empty() || ((ind_order[onset_i]+start - onset_point.back()) > 85)){
								onset_point.push_back(ind_order[onset_i] + start );
						}
					}
				}
			}
		}
	}
}


// convert CPP vector to HANA table as output
void beat_detector :: convert2Table(SharedTable &output) {
	SharedColumn col = output.columnByIndex(0);
	col.resize(onset_point.size());
	for( int i = 0;i< onset_point.size();i++){
		col.fromInt( i, onset_point[i]);
	}
	
}

// detect heart beats from original input ABP:
// step 1: convert HANA table structure to CPP vector
// step 2: clean data by a data_cleanser class
// step 3: find meaningful signal sequence, 
//         and put the sequence to an overrided  beat_detection function to detect heart beats
void beat_detector :: beat_detection(SharedTableViewer &table){
	// step 1
	SharedColumnViewer AMP = table.columnByIndex(1);
	vector<double> signal(AMP.size());
	Int temp;
	for( int i = 0;i< AMP.size();i++){
		AMP.toInt( i, temp);
		signal[i] = (double) temp.native();
	}

	//step 2: more documents about data_cleanser are available in data_cleanser.cpp
	data_cleanser cleanser(250, 10 , 3.14159,  10,  2.71828);
	
	cleanser.data_cleansing(signal);
	

	
	int count, start,onset_count = 0, current_onset_count;
	int i = 0;
	
	// step 3
	while( i< signal.size()){
		if( signal[i] == INT_MIN) i++;
		else {
			start = i;
			count = 0;
			while(i< signal.size() && signal[i]!=INT_MIN){
				count++;
				i++;
			}
			beat_detection(signal, start, count);
			
		}
	}
	
}




