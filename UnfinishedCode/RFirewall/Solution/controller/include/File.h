#pragma once

#include "OS.h"

#include "xvector.h"
#include "xstring.h"

#include <iostream>
using std::cout;
using std::endl;

struct File
{
    istatic const RE2 SoBackslashRex = R"((\\\\))";

    xstring MsPath = "";
    xstring MsData = "";
    xvector<xstring> MvsLines;
    xstring MsError = "";

    bool MbPipedData = false;
    bool MbBinary = false;
    bool MbMatches = false;
    bool MbBinarySearchOn = false;
    bool MbIndent = false;

    File();
    File(const File& FoFile);
    File(File&& FoFile);
    File(const xstring& FsPath, bool FbIsBinarySearch);
    void operator=(const File& FoFile);
    void operator=(File&& FoFile);

    void Print();
    void PrintDivider() const;
};
