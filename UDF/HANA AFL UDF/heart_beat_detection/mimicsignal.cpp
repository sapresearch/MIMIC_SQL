#include "mimicsignal.h"
#include "beat_detector.h"
/*
 * The following include is also generated automatically from the SDK build
 * tools. It contains integration code used by the AFL technology.
 */
#include "afl_mimicsignalFactory.h"

#include <hana/table.h>
#include <hana/logging.h>
#include <hana/task.h>

#include <vector>

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


/*
 * The return type AFLMETHODIMP is equivalent to void on Linux.
 *
 * For maximum portability of your code to other HANA platforms, which
 * may be supported in future, SAP recommends to use the AFLMETHODIMP macro.
 */

AFLMETHODIMP CmimicAFL::HEARTBEATDETECTION(hana::SharedTableViewer input,
                                             hana::SharedTable output) const
{
    //declare a detector for processing the ABP signal(input)
	beat_detector detector(16, 1250, 0.6, 39);
	detector.beat_detection(input);
	detector.convert2Table(output);
}



