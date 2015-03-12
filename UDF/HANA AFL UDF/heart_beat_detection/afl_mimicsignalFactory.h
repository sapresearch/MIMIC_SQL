

#ifndef __afl_mimicsignalFactory_h__
#define __afl_mimicsignalFactory_h__


#include <hana/support__.h>

#include "afl_mimicsignal.h"


extern "C" AFL_API HRESULT __stdcall
CreateAFLClassFactory( const hana::AFLTech::AFLID  & clsid,
                       const hana::AFLTech::AFLID  & iid,
                             void           ** ppv )
{
    if (clsid != mimicAFL_CLSID)
    {
        return 1;
    }

    hana::AFLTech::CCFactory<CmimicAFL> * pFactory = new hana::AFLTech::CCFactory<CmimicAFL>(mimicAFL_IID);
    if (pFactory == 0)
    {
        return 1;
    }

    return pFactory->QueryInterface( iid, ppv );
}


#endif // __afl_mimicsignalFactory_h__

