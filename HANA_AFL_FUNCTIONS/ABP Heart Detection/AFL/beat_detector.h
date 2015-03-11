#include<hana/numeric.h>
#include <hana/table.h>
#include <hana/numeric.h>
#include <hana/column.h>
#include <vector>

using namespace hana;
using namespace std;

class beat_detector{
	private:
		int beat_window_size;
		int baseline_samp_num;
		double threshold_scalar ;
		int beat_detection_width;
		
		vector<int> onset_point;
		
		void  beat_detection(vector<double> &signal, int start, int count);
		vector<double> slope_sum_function(vector<double> &signal,int start, int count);
		void decision_rule(vector<double> &slope_sum, int start);
	
	public:
		beat_detector(int,int,double,int);
		void beat_detection( SharedTableViewer &AMP);
		void convert2Table(SharedTable &output);
		
	
};
