
#include "Macros.h"

// wstring to xstring
#define wtox(PARAM) WTXS(PARAM)
//#define wtox(PARAM) ToXString<wchar_t>(PARAM)

// qstring to xstring
#define qtox(PARAM) wtox((wchar_t*)(PARAM.utf16()))

#define AddQmlClass(_ObjType_, _Obj_, _QmlObjName_) \
    RenewPtr(_Obj_, new _ObjType_()); \
    mEngine.rootContext()->setContextProperty(_QmlObjName_, _Obj_##Ptr); \
    qRegisterMetaType<_ObjType_*>("const " #_ObjType_ "*");