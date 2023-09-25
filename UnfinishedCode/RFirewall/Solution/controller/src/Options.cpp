
#include "Options.h"


Options::Rex::~Rex()
{
}

Options::~Options()
{
    if(MvoAvoidList.size())
    MvoAvoidList.clear();
    MvoAvoidFilesAndDirectoriesList.clear();
    MvoTargetFilesAndDirectoriesList.clear();
}

void Options::SetDirectory(const xstring& FsInput, bool FbUsePassword)
{
    Begin();
    if (FsInput.Scan(R"(\.\.[/\\])"))
        MbUseFullPath = true;
    else if (FsInput.Match(R"(^[A-Z]\:.*$)") && !FbUsePassword)
        MbUseFullPath = true;

    MsDirectory = RA::OS::FullPath(FsInput);
    Rescue();
}

void Options::SetRegex(const xstring& FsInput) 
{
    Begin();
#if (defined(_WIN32) || defined(WIN32) || defined(_WIN64) || defined(WIN64))
    MoRex.MsStr = xstring('(') + FsInput + ')';
    // swap a literal regex backslash for two literal backslashes
#else
    MoRex.MsStr = MoRex.MsStr + '(' + FsInput.InSub(R"(\\\\)", "\\") + ')';
#endif
    MoRex.MoRe2.MoModsPtr = MKP<re2::RE2::Options>();
    if (MoRex.MbCaseSensitive)
    {
        MoRex.MoRe2.MoModsPtr->set_case_sensitive(true);
        MoRex.MoStd.MoMods = (RXM::ECMAScript);
    }
    else {
        MoRex.MoRe2.MoModsPtr->set_case_sensitive(false);
        MoRex.MoStd.MoMods = (RXM::icase | RXM::ECMAScript);
    }
    MoRex.MoRe2.MoRexPtr = MKP<RE2>(MoRex.MsStr, MoRex.MoRe2.MoModsPtr.Get());
    MoRex.MoStd.MoRex = std::regex(MoRex.MsStr, MoRex.MoStd.MoMods);
    Rescue();
}

void Options::SetAvoidRegex(const xvector<xstring>& FvsAvoidList) 
{
    Begin();
    for (const xstring& str : FvsAvoidList)
        MvoAvoidList << MKP<RE2>(str);
    Rescue();
}

void Options::SetAvoidDirectories(const xvector<xstring>& FvsAvoidList)
{
    Begin();
    for (const xstring& str : FvsAvoidList)
        MvoAvoidFilesAndDirectoriesList << MKP<RE2>(str);
    Rescue();
}

void Options::SetTargetDirectories(const xvector<xstring>& FvsAvoidList)
{
    Begin();
    for (const xstring& str : FvsAvoidList)
        MvoTargetFilesAndDirectoriesList << MKP<RE2>(str);
    Rescue();
}

