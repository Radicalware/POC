
#include "Macros.h"

// wstring to xstring
#define wtox(PARAM) WTXS(PARAM)
//#define wtox(PARAM) ToXString<wchar_t>(PARAM)

// qstring to xstring
#define qtox(PARAM) wtox((wchar_t*)(PARAM.utf16()))

#define AddQmlClass(_ObjType_, _Obj_, _QmlObjName_) \
    RenewObject(_Obj_, _ObjType_); \
    mEngine.rootContext()->setContextProperty(_QmlObjName_, _Obj_##Ptr); \
    qRegisterMetaType<_ObjType_*>("const " #_ObjType_ "*");