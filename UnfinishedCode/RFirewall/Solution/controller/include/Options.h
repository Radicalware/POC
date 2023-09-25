#pragma once

// Copyright under the Apache v2 Licence
// Created by Joel Leaugues in 2020

// -------------- STL -------------------
#include <iostream>
using std::cout;
using std::endl;
// -------------- STL -------------------
// ---------- RADICALWARE ---------------
#include "Nexus.h"
#include "xvector.h"
#include "xstring.h"
#include "OS.h"
#include "Memory.h"
// ---------- RADICALWARE ---------------



struct Options
{
    struct Rex
    {
        struct g2
        {
            xp<RE2> MoRexPtr = nullptr;
            xp<re2::RE2::Options> MoModsPtr;
        };
        struct stl
        {
            std::regex MoRex;
            RXM::Type MoMods;
        };

        g2 MoRe2;
        stl MoStd;

        xstring MsStr = "";
        bool MbCaseSensitive = false;

        Rex() {}
        ~Rex();
    };
    Options() {};
    ~Options();

    Rex MoRex;
    xvector<xp<RE2>> MvoAvoidList;
    xvector<xp<RE2>> MvoAvoidFilesAndDirectoriesList;
    xvector<xp<RE2>> MvoTargetList;
    xvector<xp<RE2>> MvoTargetFilesAndDirectoriesList;
    xstring MsDirectory = "";

    bool MbUseFullPath = false;
    bool MbOnlyNameFiles = false;
    bool MbLineTrackerOn = false;
    bool MbBinaraySearchOn = false;
    bool MbEntire = false;
    bool MbPiped = false;
    bool MbModify = false;
    bool MoIncludeLockedFileErros = false;

    void SetDirectory(const xstring& FsInput, bool FbUsePassword = false);
    void SetRegex(const xstring& FsInput);
    void SetAvoidRegex(const xvector<xstring>& FvsAvoidList);
    void SetAvoidDirectories(const xvector<xstring>& FvsAvoidList);
    void SetTargetDirectories(const xvector<xstring>& FvsAvoidList);
};