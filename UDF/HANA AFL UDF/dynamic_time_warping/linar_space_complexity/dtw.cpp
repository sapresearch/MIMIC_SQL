#include "dtw.h"
#include "distance.h"

/*
 * The following include is also generated automatically from the SDK build
 * tools. It contains integration code used by the AFL technology.
 */
#include "afl_dtwFactory.h"

#include <hana/table.h>
#include <hana/logging.h>
#include <hana/task.h>

#include <vector>
#include <climits>
#include <algorithm>
#include <cmath>
#include <iostream>
#include <cfloat>
#if __cplusplus >= 201103L
#   include <memory>
namespace cpp11 = std
#elif defined (__GNUC__) && __GNUC__ >= 4 && defined (__GLIBCXX__)
#   include <tr1/memory>
namespace cpp11 = std::tr1;
#elif defined (_MSC_VER) && (_MSC_VER == 1500 && defined (_HAS_TR1) || _MSC_VER > 1500)
#   include <memory>
namespace cpp11 = stdext;
#else
#   error "unsupported platform/compiler"
#endif

using namespace std;
using namespace hana;

/*
 * The return type AFLMETHODIMP is equivalent to void on Linux.
 *
 * For maximum portability of your code to other HANA platforms, which
 * may be supported in future, SAP recommends to use the AFLMETHODIMP macro.
 */



AFLMETHODIMP CDTWAFL::DTW(hana::SharedTableViewer inputtable1,hana::SharedTableViewer inputtable2, hana::SharedTableViewer inputtable3, hana::SharedTable output) const
{	String temp_distance_type;
	inputtable3.columnByIndex(0).toString(0,temp_distance_type);
	string distance_type = temp_distance_type.c_str();
	DistanceFunction* FN = DistanceFactory::getDistFunctionbyName(distance_type);
	
	
	Int temp_size;
	inputtable3.columnByIndex(1).toInt(0,temp_size);
	uint64_t window_size = temp_size.native();
	
	
    SharedColumnViewer signal_x = inputtable1.columnByIndex(0);
	SharedColumnViewer signal_y = inputtable2.columnByIndex(0);
	
	if(signal_x.size() != signal_y.size()){
		cout<< "length of two signal should be the same"<<endl;
		SharedColumn col_similarity = output.columnByIndex(0);
		col_similarity.resize(1);
		col_similarity.fromDouble(0,INT_MAX);
		return;
	}
	
	
	uint64_t size = signal_x.size();
	
	vector<double> prev_row(size,INT_MAX);
	vector<double> cur_row(size,INT_MAX);
	
	Double val_x, val_y;
	signal_x.toDouble(0,val_x);
	signal_y.toDouble(0,val_y);
	double double_val_x, double_val_y;
	double_val_x =(double)val_x.native();
	double_val_y =(double)val_y.native();
	prev_row[0] = FN->calDistance( double_val_x>0 ? double_val_x:0, double_val_y>0 ? double_val_y:0 );
	
	for( uint64_t i = 1; i< min(window_size, size); i++){
		signal_x.toDouble(0,val_x);
		signal_y.toDouble(i,val_y);
		double_val_x =(double)val_x.native();
		double_val_y =(double)val_y.native();
		prev_row[i] = prev_row[i-1] + FN->calDistance( double_val_x>0 ? double_val_x:0, double_val_y>0 ? double_val_y:0 ); 
	}
	
	for( uint64_t i = 1; i< size;i++){
		signal_x.toDouble(i,val_x);
		signal_y.toDouble(0,val_y);
		double_val_x =(double)val_x.native();
		double_val_y =(double)val_y.native();
		cur_row[0] = prev_row[0] + FN->calDistance( double_val_x>0 ? double_val_x:0, double_val_y>0 ? double_val_y:0 ); 
		for( uint64_t j = max(1, (int)i-(int)window_size); j < min( size, i+window_size+1);j++){
			signal_x.toDouble(i,val_x);
			signal_y.toDouble(j,val_y);
			double_val_x =(double)val_x.native();
			double_val_y =(double)val_y.native();
			cur_row[j] = min( prev_row[j-1], min( prev_row[j], cur_row[j-1]) ) + FN->calDistance( double_val_x>0 ? double_val_x:0, double_val_y>0 ? double_val_y:0 ); 
		}
		prev_row = cur_row;
	}


	SharedColumn col_similarity = output.columnByIndex(0);
	col_similarity.resize(1);
	col_similarity.fromDouble(0,cur_row[size-1]);
	


}

