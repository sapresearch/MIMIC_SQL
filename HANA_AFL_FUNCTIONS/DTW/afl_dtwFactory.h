

#ifndef __afl_dtwFactory_h__
#define __afl_dtwFactory_h__


#include <hana/support__.h>

#include "afl_dtw.h"


extern "C" AFL_API HRESULT __stdcall
CreateAFLClassFactory( const hana::AFLTech::AFLID  & clsid,
                       const hana::AFLTech::AFLID  & iid,
                             void           ** ppv )
{
    if (clsid != DTWAFL_CLSID)
    {
        return 1;
    }

    hana::AFLTech::CCFactory<CDTWAFL> * pFactory = new hana::AFLTech::CCFactory<CDTWAFL>(DTWAFL_IID);
    if (pFactory == 0)
    {
        return 1;
    }

    return pFactory->QueryInterface( iid, ppv );
}


#endif // __afl_dtwFactory_h__

