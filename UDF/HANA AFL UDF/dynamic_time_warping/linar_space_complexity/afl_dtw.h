

#ifndef __afl_dtw_h__
#define __afl_dtw_h__


#include <hana/config__.h>
#include <hana/support__.h>
#include <hana/table.h>
#include <hana/column.h>
#include <hana/string.h>
static const hana::AFLTech::AFLID DTWAFL_IID = { 0xB68B6E4D, 0xE21C, 0x4747, { 0xA9, 0x5D, 0x19, 0x9C, 0xDD, 0x58, 0x54, 0xEA } };

class IDTWAFL
{
public:
    virtual ~IDTWAFL() {}

    STDMETHOD(QueryInterface)( const hana::AFLTech::AFLID  & iid,
                                     void           ** ppv ) = 0;

    AFLMETHOD(DTW)(
        /* in */ hana::SharedTableViewer inputtable1,
        /* in */ hana::SharedTableViewer inputtable2,
        /* in */ hana::SharedTableViewer inputtable3,
        /* out */ hana::SharedTable outputTable1,
        /* out */ hana::SharedTable outputTable2 ) const = 0;
};

static const hana::AFLTech::AFLID DTWAFL_CLSID = { 0x900AB60B, 0x8D93, 0x4536, { 0xB2, 0x54, 0x21, 0xC3, 0x42, 0x46, 0x59, 0x54 } };



#endif // __afl_dtw_h__

