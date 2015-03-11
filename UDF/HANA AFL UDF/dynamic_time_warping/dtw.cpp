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



AFLMETHODIMP CDTWAFL::DTW(hana::SharedTableViewer inputtable1,hana::SharedTableViewer inputtable2, hana::SharedTableViewer inputtable3, hana::SharedTable output, hana::SharedTable output_path) const
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
		return;
	}
	
	
	uint64_t size = signal_x.size();
	
	vector< vector<double> > matrix(size,vector<double>(size, INT_MAX));
	
	Double val_x, val_y;
	signal_x.toDouble(0,val_x);
	signal_y.toDouble(0,val_y);
	matrix[0][0] = FN->calDistance( (double)val_x.native(),   (double)val_y.native() );
	for( uint64_t i = 1; i< min(window_size, size); i++){
		signal_x.toDouble(i,val_x);
		signal_y.toDouble(0,val_y);
		matrix[i][0] = matrix[i-1][0] + FN->calDistance( (double)val_x.native(),   (double)val_y.native() ); 
		
		signal_x.toDouble(0,val_x);
		signal_y.toDouble(i,val_y);
		matrix[i][0] = matrix[0][i-1] + FN->calDistance( (double)val_x.native(),   (double)val_y.native() ); 
	}
	
	for( uint64_t i = 1; i< size;i++){
		for( uint64_t j = max(1, (int)i-(int)window_size); j < min( size, i+window_size+1);j++){
			signal_x.toDouble(i,val_x);
			signal_y.toDouble(j,val_y);
			matrix[i][j] = min( matrix[i-1][j-1], min( matrix[i-1][j], matrix[i][j-1]) ) + FN->calDistance( (double)val_x.native(),   (double)val_y.native() ); 
		}
	}


	SharedColumn col_similarity = output.columnByIndex(0);
	col_similarity.resize(1);
	col_similarity.fromDouble(0,matrix[size-1][size-1]);
	
	uint64_t row = 0, col = 0;
	vector< pair<uint64_t,uint64_t> > coordinate;
	while(row < size && col < size){
		double candadite1, candadite2,candadite3;
		candadite1 = (row+1 < size) ? matrix[row+1][col]:DBL_MAX;
		candadite2 = (col+1 < size) ? matrix[row][col+1]:DBL_MAX;
		candadite3 = (row+1 < size && col+1 < size) ? matrix[row+1][col+1]:DBL_MAX;
		if( candadite1 < candadite2 && candadite1 < candadite3) {
			pair<uint64_t,uint64_t> temp_pair(row+1,col);
			coordinate.push_back(temp_pair);
		// save (row+1, col)
			row++;
		}
		else if(candadite2 < candadite1 && candadite2 < candadite3){
			pair<uint64_t,uint64_t> temp_pair(row+1,col);
			coordinate.push_back(temp_pair);
		// save (row, col+1)
			col++;
		}
		else {
			pair<uint64_t,uint64_t> temp_pair(row+1,col);
			coordinate.push_back(temp_pair);
		// save (row+1,col+1);
			row++;
			col++;
		}
	}
	SharedColumn col_x = output_path.columnByIndex(0);
	SharedColumn col_y = output_path.columnByIndex(1);
	col_x.resize(coordinate.size()+1);
	col_y.resize(coordinate.size()+1);
	col_x.fromInt(0,0);
	col_y.fromInt(0,0);
	for( uint64_t i = 1;i< coordinate.size()+1;i++){
		col_x.fromInt(i,coordinate[i-1].first);
		col_y.fromInt(i,coordinate[i-1].second);
	}
		col_x.fromInt(size,size-1);
		col_y.fromInt(size,size-1);

}

