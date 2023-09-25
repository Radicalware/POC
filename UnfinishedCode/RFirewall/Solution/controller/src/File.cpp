#include "File.h"


#define ReadFileCatch \
    catch (std::runtime_error& errstr) { \
        The.MsData.clear(); \
        The.MsError = errstr.what(); \
    } \
    catch (...) \
    { \
        The.MsData.clear(); \
        The.MsError = "Could Not Open/Read File"; \
    }

File::File()
{
}

File::File(const File& FoFile)
{
    The = FoFile;
}

File::File(File&& FoFile)
{
    The = std::move(FoFile);
}

File::File(const xstring& FsPath, bool FbIsBinarySearch)
{
    Begin();
    MsPath = FsPath;
    MbBinarySearchOn = FbIsBinarySearch;
    if (MbBinarySearchOn)
    {
#if (defined(_WIN32) || defined(WIN32) || defined(_WIN64) || defined(WIN64))
        bool LbOpenFailure = false;
        try {
            MsData = RA::OS::ReadFile(MsPath);
        }
        ReadFileCatch

        if (LbOpenFailure)
        {
            try {
                MsData = RA::OS::ReadStreamMethod(MsPath);
            }
            ReadFileCatch
        }
#else
        try {
            MsData = RA::OS::ReadStatMethod(MsPath);
        }   
        ReadFileCatch
#endif
    }
    else { // not binary searching
        try {
            MsData = RA::OS::ReadFile(MsPath).RemoveNonAscii();
        }
        ReadFileCatch
    }
    FinalRescue();
}

void File::operator=(const File& FoFile)
{
    The.MsPath             = FoFile.MsPath;
    The.MsData             = FoFile.MsData;
    The.MvsLines           = FoFile.MvsLines;
    The.MbBinary           = FoFile.MbBinary;
    The.MbMatches          = FoFile.MbMatches;
    The.MbBinarySearchOn   = FoFile.MbBinarySearchOn;
}

void File::operator=(File&& FoFile)
{
    The.MsPath             = std::move(FoFile.MsPath);
    The.MsData             = std::move(FoFile.MsData);
    The.MvsLines           = std::move(FoFile.MvsLines);
    The.MbBinary           = FoFile.MbBinary;
    The.MbMatches          = FoFile.MbMatches;
    The.MbBinarySearchOn   = FoFile.MbBinarySearchOn;
}


void File::Print()
{
    Begin();
    bool LbPrinted = false;
    char spacer[3];
    if (!MbPipedData)
        strncpy(spacer, "\n\n\0", 3);
    else
        strncpy(spacer, "\0", 3);

    if (The.MbMatches && !The.MbBinary)
    {
        The.PrintDivider();
#pragma warning (suppress : 6053) // Above I enusre we get null bytes for spacer
        cout << Color::Mod::Bold << Color::Cyan << ">>> FILE: >>> " << The.MsPath.InSub(SoBackslashRex, "\\\\") << spacer << Color::Mod::Reset;
        LbPrinted = true;
    }

    // bool line_match = false; // Code review : TBR
    for (const xstring& line : MvsLines)
    {
        if (line.size())
            line.Print();
    }
    if(LbPrinted && !MbPipedData)
        cout << '\n';
    Rescue();
}

void File::PrintDivider() const
{
    cout << Color::Blue << xstring(RA::OS::GetConsoleSize()[0], '-') << Color::Mod::Reset;
}