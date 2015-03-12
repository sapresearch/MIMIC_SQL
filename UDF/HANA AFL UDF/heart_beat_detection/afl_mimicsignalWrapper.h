

#ifndef __afl_mimicsignalWrapper_h__
#define __afl_mimicsignalWrapper_h__


#include "afl_mimicsignal.h"


/*----------------------------------------------------------------------------*/

extern "C" AFL_API AFL_ReturnCode __stdcall
HEARTBEATDETECTION__Wrapper(
    void *  pCOMIF,
    void ** pParamPtr,
    int     paramCnt )
{
    if (paramCnt != 2)
    {
        return AFL_BadParamCount;
    }

    ImimicAFL * pIfc = (ImimicAFL *)pCOMIF;

    hana::PrivateData__ data0;
    data0.representation = pParamPtr[0];
    data0.syncBack = false;
    hana::SharedTableViewer param0(&data0);

    hana::PrivateData__ data1;
    data1.representation = pParamPtr[1];
    data1.syncBack = true;
    hana::SharedTable param1(&data1);

    pIfc->HEARTBEATDETECTION(
               param0
             , param1
             );

    return AFL_OK;
}


#endif // __afl_mimicsignalWrapper_h__

