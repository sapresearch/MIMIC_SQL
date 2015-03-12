#ifndef INTRO_AFL_H__
#define INTRO_AFL_H__

/*
 * The afl_intro.h is a automatically generated when the SDK build tools run.
 */
#include "afl_mimicsignal.h"

/*
 * This is the AFL main class. As explained in afl_intro.afx it follows the
 * IxxxAFL and CxxxAFL naming convention. It must inherit from the  base
 * interface contained the afl_intro.h file.
 *
 * The AFs described in the afl_intro.afx are declared here and implemented
 * in the intro.cpp file.
 */
class CmimicAFL:
        public ImimicAFL
{
public:
    CmimicAFL () {}
    virtual ~CmimicAFL() {}

    /*
     * This macros allows the back-end to get a handle to this AFL and
     * eventually invoke the AFs.
     */
    AFL_QUERYINTERFACE(mimicAFL);

    /*
     * Below are the C++ counter-parts of the two AFs described in the
     * afl_intro.afx file. With these examples all possible parameters
     * types are illustrated.
     *
     * A declaration
     *   AFLMETHOD(method_name)(...) const;
     * is equivalent to
     *   virtual void method_name(...) const;
     * on Linux.
     *
     * For maximum portability of your code to other HANA platforms, which
     * may be supported in future, SAP recommends to use the AFLMETHOD macro.
     */


    AFLMETHOD(HEARTBEATDETECTION)(hana::SharedTableViewer,
                                            hana::SharedTable) const;

	
};

#endif // INTRO_AFL_H__
