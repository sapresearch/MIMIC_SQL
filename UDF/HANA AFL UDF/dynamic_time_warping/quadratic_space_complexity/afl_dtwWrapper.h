

#ifndef __afl_dtwWrapper_h__
#define __afl_dtwWrapper_h__


#include "afl_dtw.h"


/*----------------------------------------------------------------------------*/

extern "C" AFL_API AFL_ReturnCode __stdcall
DTW__Wrapper(
    void *  pCOMIF,
    void ** pParamPtr,
    int     paramCnt )
{
    if (paramCnt != 5)
    {
        return AFL_BadParamCount;
    }

    IDTWAFL * pIfc = (IDTWAFL *)pCOMIF;

    hana::PrivateData__ data0;
    data0.representation = pParamPtr[0];
    data0.syncBack = false;
    hana::SharedTableViewer param0(&data0);

    hana::PrivateData__ data1;
    data1.representation = pParamPtr[1];
    data1.syncBack = false;
    hana::SharedTableViewer param1(&data1);

    hana::PrivateData__ data2;
    data2.representation = pParamPtr[2];
    data2.syncBack = false;
    hana::SharedTableViewer param2(&data2);

    hana::PrivateData__ data3;
    data3.representation = pParamPtr[3];
    data3.syncBack = true;
    hana::SharedTable param3(&data3);

    hana::PrivateData__ data4;
    data4.representation = pParamPtr[4];
    data4.syncBack = true;
    hana::SharedTable param4(&data4);

    pIfc->DTW(
               param0
             , param1
             , param2
             , param3
             , param4
             );

    return AFL_OK;
}


#endif // __afl_dtwWrapper_h__

