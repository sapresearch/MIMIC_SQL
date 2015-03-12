
#include<vector>

using namespace std;
class data_cleanser{
	private:
		int min_sequence;
		int filter_size;
		double pi;
		int sigma;
		double exp;
		
		vector<double> gaussianFilter(vector<double> &rawsignal);
	
	public:
		data_cleanser(int seq, int filter_S ,double p , int s, double e);
		
		void data_cleansing(vector<double> &signal);
		
		
};
