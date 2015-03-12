

#ifndef __afl_mimicsignal_h__
#define __afl_mimicsignal_h__


#include <hana/config__.h>
#include <hana/support__.h>
#include <hana/table.h>
#include <hana/column.h>
#include <hana/string.h>
static const hana::AFLTech::AFLID mimicAFL_IID = { 0xB68B6E4D, 0xE21C, 0x4747, { 0xA9, 0x5D, 0x19, 0x9C, 0xDD, 0x58, 0x54, 0xEA } };

class ImimicAFL
{
public:
    virtual ~ImimicAFL() {}

    STDMETHOD(QueryInterface)( const hana::AFLTech::AFLID  & iid,
                                     void           ** ppv ) = 0;

    AFLMETHOD(HEARTBEATDETECTION)(
        /* in */ hana::SharedTableViewer inputTable,
        /* out */ hana::SharedTable outputTable ) const = 0;
};

static const hana::AFLTech::AFLID mimicAFL_CLSID = { 0x900AB60B, 0x8D93, 0x4536, { 0xB2, 0x54, 0x21, 0xC3, 0x42, 0x46, 0x59, 0x54 } };



#endif // __afl_mimicsignal_h__

