
#include<iostream>

using std::cout;
using std::endl;

#define DeleteObject(OBJ) \
    if (OBJ) delete OBJ;

#define InitClassObject(OBJ) \
    DeleteObject(OBJ); \
    OBJ = new std::remove_pointer<decltype(OBJ)>::type;

#define REF(OBJ, TYPE) \
    if(!OBJ##Ptr){ \
        cout << "Unable to deref: " << #OBJ << "Ptr" << '\n'; \
        return TYPE; \
    } \
    auto& OBJ = *OBJ##Ptr;


// wstring to xstring
#define wtox(PARAM) WTXS(PARAM)
//#define wtox(PARAM) ToXString<wchar_t>(PARAM)

// qstring to xstring
#define qtox(PARAM) wtox((wchar_t*)(PARAM.utf16()))

#define AddQmlClass(ObjType, ObjPtr, QmlObjName) \
    InitClassObject(ObjPtr); \
    mEngine.rootContext()->setContextProperty(QmlObjName, ObjPtr); \
    qRegisterMetaType<ObjType*>("const " #ObjType "*");