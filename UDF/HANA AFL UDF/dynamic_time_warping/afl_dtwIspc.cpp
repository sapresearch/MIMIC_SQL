

#include <string.h>

#include "afl_dtwWrapper.h"


/*----------------------------------------------------------------------------*/

extern "C" AFL_API void __stdcall
IntrospectAFL( hana::AFLTech::AFLID & clsid,
               hana::AFLTech::AFLID & iid )
{
    memcpy( &clsid, &DTWAFL_CLSID, sizeof(hana::AFLTech::AFLID) );
    memcpy( &iid,   &DTWAFL_IID,   sizeof(hana::AFLTech::AFLID) );
}

/*----------------------------------------------------------------------------*/

typedef struct
{
    char *        pIOType;
    short int     Datatype;
    short int     SubDatatype;
    short int     CsDatatype;
    short int     SqlDatatype;
    short int     Length;
    short int     Dim;
    int           OffsetServer;
    int           OffsetAsciiClient;
    int           OffsetUnicodeClient;
    unsigned char Frac;
    char *        pParamName;
} AppFunc_ParamDesc;

typedef struct
{
    char * pKey;
    char * pValue;
} AppFunc_PropDesc;

static void __stdcall Introspect_AppFunc1_Param(
    unsigned short  ParamIdx,
    char **         ppIOType,
    short int *     pDatatype,
    short int *     pSubDatatype,
    short int *     pCsDatatype,
    short int *     pSqlDatatype,
    short int *     pLength,
    short int *     pDim,
    int *           pOffsetServer,
    int *           pOffsetAsciiClient,
    int *           pOffsetUnicodeClient,
    unsigned char * pFrac,
    char **         ppParamName )
{
    static const AppFunc_ParamDesc ParamDesc[] =
    {
        (char*)"IN", 225, 0, 0, 0, 0, 1, 0, 0, 0, 0, (char*)"inputtable1",
        (char*)"I/O", 226, 0,  0, 0, 0, 0, 0, 0, 0, 0, (char*)"[ID]",
        (char*)"IN", 225, 0, 0, 0, 0, 1, 0, 0, 0, 0, (char*)"inputtable2",
        (char*)"I/O", 226, 0,  0, 0, 0, 0, 0, 0, 0, 0, (char*)"[ID]",
        (char*)"IN", 225, 0, 0, 0, 0, 1, 0, 0, 0, 0, (char*)"inputtable3",
        (char*)"I/O", 226, 0,  0, 0, 0, 0, 0, 0, 0, 0, (char*)"SI",
        (char*)"OUT", 225, 0, 0, 0, 0, 1, 0, 0, 0, 0, (char*)"outputTable1",
        (char*)"I/O", 226, 0,  0, 0, 0, 0, 0, 0, 0, 0, (char*)"[ID]",
        (char*)"OUT", 225, 0, 0, 0, 0, 1, 0, 0, 0, 0, (char*)"outputTable2",
        (char*)"I/O", 226, 0,  0, 0, 0, 0, 0, 0, 0, 0, (char*)"[DI][DI]"
    };

    if ( (ParamIdx > (sizeof(ParamDesc) / sizeof(AppFunc_ParamDesc))) || (ParamIdx < 1) )
    {
        *ppIOType             = NULL;
        *pDatatype            = 0;
        *pSubDatatype         = 0;
        *pCsDatatype          = 0;
        *pSqlDatatype         = 0;
        *pLength              = 0;
        *pDim                 = 0;
        *pOffsetServer        = 0;
        *pOffsetAsciiClient   = 0;
        *pOffsetUnicodeClient = 0;
        *pFrac                = 0;
        *ppParamName          = NULL;
    }
    else
    {
        *ppIOType             = ParamDesc[ParamIdx-1].pIOType;
        *pDatatype            = ParamDesc[ParamIdx-1].Datatype;
        *pSubDatatype         = ParamDesc[ParamIdx-1].SubDatatype;
        *pCsDatatype          = ParamDesc[ParamIdx-1].CsDatatype;
        *pSqlDatatype         = ParamDesc[ParamIdx-1].SqlDatatype;
        *pLength              = ParamDesc[ParamIdx-1].Length;
        *pDim                 = ParamDesc[ParamIdx-1].Dim;
        *pOffsetServer        = ParamDesc[ParamIdx-1].OffsetServer;
        *pOffsetAsciiClient   = ParamDesc[ParamIdx-1].OffsetAsciiClient;
        *pOffsetUnicodeClient = ParamDesc[ParamIdx-1].OffsetUnicodeClient;
        *pFrac                = ParamDesc[ParamIdx-1].Frac;
        *ppParamName          = ParamDesc[ParamIdx-1].pParamName;
    }
}

static void __stdcall Introspect_AppFunc1_Prop(
    unsigned short PropIdx,
    char **        ppKey,
    char **        ppValue )
{
    *ppKey   = NULL;
    *ppValue = NULL;
}

/*----------------------------------------------------------------------------*/

typedef void (__stdcall * Introspect_AppFunc_Param)
(
    unsigned short  ParamIdx,
    char **         ppIOType,
    short int *     pDatatype,
    short int *     pSubDatatype,
    short int *     pCsDatatype,
    short int *     pSqlDatatype,
    short int *     pLength,
    short int *     pDim,
    int *           pOffsetServer,
    int *           pOffsetAsciiClient,
    int *           pOffsetUnicodeClient,
    unsigned char * pFrac,
    char **         ppParamName
);

typedef void (__stdcall * Introspect_AppFunc_Prop)
(
    unsigned short PropIdx,
    char **        ppKey,
    char **        ppValue
);

enum AppFunc_Type
{
    LFunc = 1,
    Pop   = 2,
    Proc  = 4
};

enum AppFunc_Category
{
    cat_empty   = 0,
    var_none    = 1,
    var_names   = 2,
    var_columns = 4
};

typedef struct
{
    unsigned short            FuncIdx;
    char *                    pFuncName;
    unsigned short            ParamCount;
    Introspect_AppFunc_Param  pIntrospectParam;
    AppFunc_Type              Type;
    AppFunc_Category          Category;
    unsigned short            PropCount;
    Introspect_AppFunc_Prop   pIntrospectProp;
    char *                    pBusinessCat;
} AppFunc_Desc;

/*----------------------------------------------------------------------------*/

const AppFunc_Desc AF_Desc[] =
{
    1, (char*)"DTW", 10, &Introspect_AppFunc1_Param, LFunc, var_columns, 0, &Introspect_AppFunc1_Prop, (char*)""
};

/*----------------------------------------------------------------------------*/

enum AccessType
{
    get_by_name,
    get_by_index
};

#define AF_NUM 1

/*----------------------------------------------------------------------------*/

extern "C" AFL_API void __stdcall
IntrospectAppFunc( AccessType                  accessType,
                   char                     ** ppFunction,
                   unsigned short              num,
                   unsigned short            * pIdx,
                   unsigned short            * pParamCount,
                   Introspect_AppFunc_Param  * ppIntrospectParam,
                   AppFunc_Type              * pType,
                   AppFunc_Category          * pCategory,
                   unsigned short            * pPropCount,
                   Introspect_AppFunc_Prop   * ppIntrospectProp,
                   char                     ** ppBusinessCat )
{
    *ppIntrospectParam = NULL;

    if (accessType == get_by_name)
    {
        for ( int i = 0; i < AF_NUM; i++ )
        {
            if (0 == strcmp( *ppFunction, AF_Desc[i].pFuncName ))
            {
                *pIdx              = AF_Desc[i].FuncIdx;
                *pParamCount       = AF_Desc[i].ParamCount;
                *ppIntrospectParam = AF_Desc[i].pIntrospectParam;
                *pType             = AF_Desc[i].Type;
                *pCategory         = AF_Desc[i].Category;
                *pPropCount        = AF_Desc[i].PropCount;
                *ppIntrospectProp  = AF_Desc[i].pIntrospectProp;
                *ppBusinessCat     = AF_Desc[i].pBusinessCat;
                break;
            }
        }
    }
    else
    {
        if ( (1 <= num) && (num <= AF_NUM) )
        {
            *ppFunction        = AF_Desc[num-1].pFuncName;
            *pIdx              = AF_Desc[num-1].FuncIdx;
            *pParamCount       = AF_Desc[num-1].ParamCount;
            *ppIntrospectParam = AF_Desc[num-1].pIntrospectParam;
            *pType             = AF_Desc[num-1].Type;
            *pCategory         = AF_Desc[num-1].Category;
            *pPropCount        = AF_Desc[num-1].PropCount;
            *ppIntrospectProp  = AF_Desc[num-1].pIntrospectProp;
            *ppBusinessCat     = AF_Desc[num-1].pBusinessCat;
        }
    }
}

