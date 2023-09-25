#include "Core.h"
#include "OS.h"
#include "xstring.h"

#pragma warning( disable : 26812 ) // to allow our rxm enum even though it isn't a class enum

void Core::Filter()
{
    Begin();
    // Filter over the avoid list.
    if (!MoOption.MvoAvoidFilesAndDirectoriesList.empty())
    {
        for (auto& x : MoOption.MvoAvoidFilesAndDirectoriesList)
            MvsFileList.erase(
                std::remove_if(MvsFileList.begin(), MvsFileList.end(),
                    [&x](xstring& element) { return element.Scan(x->pattern(), RXM::icase); }),
                MvsFileList.end());
        (Color::Cyan << "Files in Dir (Filtered over exclusions): " << MvsFileList.size() << Color::Mod::Reset).Print();
    }

    if (!MoOption.MvoTargetFilesAndDirectoriesList.empty())
    {
        for (auto& x : MoOption.MvoTargetFilesAndDirectoriesList)
            MvsFileList.erase(
                std::remove_if(MvsFileList.begin(), MvsFileList.end(),
                    [&x](xstring& TgtFile) { return !TgtFile.Scan(x->pattern(), RXM::icase); }),
                MvsFileList.end());
        (Color::Cyan << "Files in Dir (Targets): " << MvsFileList.size() << Color::Mod::Reset).Print();
    }
    Rescue();
}

Core::Core(const Options& options) : MoOption(options)
{
}

void Core::PipedScan()
{
    Begin();
    MoFilePtr = MKP<File>();
    GET(MoFile);

    MoFile.MbPipedData = true;

    MoFile.MsPath = "Piped Data";
    if (MoOption.MbEntire)
        MoFile.MbIndent = true;

    xstring LsLine = "";
    // unsigned long int LnLineNumber = 0; // Code review: Unused code. TBR.

    while (getline(std::cin, LsLine))
    {
        if (MoOption.MbEntire && LsLine.Size() == 0)
        {
            MoFile.MvsLines << '\0';
            continue;
        }
        xvector<xstring> LvsSegments = LsLine.InclusiveSplit(MoOption.MoRex.MoStd.MoRex, false);
        xstring LsColoredLine = "";
        if (LvsSegments.Size())
        {
            bool LbMatchOn = false;
            if (LvsSegments[0].Match(*MoOption.MoRex.MoRe2.MoRexPtr))
                LbMatchOn = true;

            for (const xstring& seg : LvsSegments)
            {
                if (LbMatchOn)
                {
                    LsColoredLine += Color::Mod::Bold + Color::Red + seg + Color::Mod::Reset;
                    LbMatchOn = false;
                }
                else {
                    LsColoredLine += seg;
                    LbMatchOn = true;
                }
            }
            MoFile.MvsLines << LsColoredLine;
        }
        else if (MoOption.MbEntire)
        {
            MoFile.MvsLines << LsLine;
        }
    }
    Rescue();
}

void Core::ScanFile(xstring& FsPath)
{
    Begin();

    //xstring Str = "C:\Source\Radicalware\Applications\Multi\Scan\file.cpp";

    // lambdas prevent you from getting exception visibiliity so I won't use them here
    auto AddFile = [](Core& FThis, const xp<File>& FoFilePtr) -> void
    {
        Begin();
        auto Lock = FThis.MvoFiles.CreateLock();
        FThis.MvoFiles << FoFilePtr;
        FinalRescue();
    };


    GET(Rex, MoOption.MoRex.MoRe2.MoRexPtr);
    //auto& Rex = MoOption.MoRex.MoStd.MoRex;

    if (!MoOption.MbUseFullPath)
        FsPath = '.' + FsPath(static_cast<double>(MsPWD.Size()));

    GET(LoFile, MKP<File>(FsPath, MoOption.MbBinaraySearchOn));
    if (LoFile.MsError.Size())
    {
        LoFile.MsData.clear();
        return AddFile(The, LoFilePtr);
        //auto Lock = MvoFiles.CreateLock();
        //MvoFiles << MoFilePtr;
        //return;
    }

    bool LbAvoid  = static_cast<bool>(MoOption.MvoAvoidList.Size());
    bool LbTarget = static_cast<bool>(MoOption.MvoTargetList.Size());
    try
    {
        LoFile.MbMatches = LoFile.MsData.Scan(Rex);
    }catch(...)
    {
        auto Lock = MvoFiles.CreateLock();
        ("Can't Scan File: " + LoFile.MsPath + '\n').Print();
    }

    if (!LoFile.MbMatches)
    {
        LoFile.MsData.clear();
        return AddFile(The, LoFilePtr);
    }

    if (MoOption.MbModify)
        return AddFile(The, LoFilePtr);

    if (MoOption.MbBinaraySearchOn)
    {
        LoFile.MbBinary = LoFile.MsData.HasDualNulls();
        if (LoFile.MbBinary)
        {
            LoFile.MsData.clear();
            return AddFile(The, LoFilePtr);
        }
    }

    xstring LsLineNumberString = "";
    xstring LsSpacer = '.';
    if (MoOption.MbOnlyNameFiles)
    {
        if (LbTarget)
            LoFile.MbMatches = (LoFile.MbMatches && LoFile.MsData.ScanList(MoOption.MvoTargetList));
        
        if (LbAvoid && !(LbTarget && LoFile.MbMatches))
            LoFile.MbMatches = (LoFile.MbMatches && !LoFile.MsData.ScanList(MoOption.MvoAvoidList));
    }
    else {
        unsigned long int LnLineNumber = 0;
        for (const xstring& line : LoFile.MsData.Split('\n'))
        {
            if (LbTarget) {
                if (!line.ScanList(MoOption.MvoTargetList))
                    continue;
            }

            if (LbAvoid) {
                if (line.ScanList(MoOption.MvoAvoidList))
                    continue;
            }

            LnLineNumber++;
            LsLineNumberString = RA::ToXString(LnLineNumber);
            xvector<xstring> LvSegs = line.InclusiveSplit(MoOption.MoRex.MoStd.MoRex, false);
            xstring LsColoredLine = "";
            if (LvSegs.size())
            {
                LsColoredLine = Color::Mod::Bold + Color::Cyan + "Line " + (LsSpacer * (7 - LsLineNumberString.Size())) + ' ' + LsLineNumberString + ": " + Color::Mod::Reset;
                LoFile.MbMatches = true;
                bool LbMatchOn = false;
                if (LvSegs[0].Match(Rex))
                    LbMatchOn = true;

                LvSegs[0].LeftTrim();
                bool LbHasRealFind = false;
                for (xstring& LsSeg : LvSegs)
                {
                    if (!LsSeg)
                        continue;

                    if (LbMatchOn)
                    {
                        LbHasRealFind = true;
                        LsColoredLine += Color::Mod::Bold + Color::Red + LsSeg + Color::Mod::Reset;
                        LbMatchOn = false;
                    }
                    else {
                        LsColoredLine += LsSeg;
                        LbMatchOn = true;
                    }
                }

                if(LbHasRealFind)
                    LoFile.MvsLines << LsColoredLine;
            }
        }
    }

    if (!LoFile.MvsLines.Size() && !MoOption.MbOnlyNameFiles) // Code review: MvsLines is not alwasys avialable 
        LoFile.MbMatches = false;
    LoFile.MsData.clear();
    AddFile(The, LoFilePtr);
    Rescue();
}

void Core::MultiCoreScan()
{
    Begin();
    MvsFileList = 
        RA::OS::Dir(MoOption.MsDirectory, 'd')
        .ForEachThread<xvector<xstring>>([](xstring& dir) { return RA::OS::Dir(dir, 'r', 'f'); })
        .Expand();
    MvsFileList += RA::OS::Dir(MoOption.MsDirectory, 'f');

    Filter();
    (Color::Cyan << "Files in Dir: " << MvsFileList.size() << Color::Mod::Reset).Print();
    
    // xrender is multi-threaded
    // "this" is passed in with std::ref but never modified
    MvoFiles.clear();
    MvoFiles.CreateMTX();
    Nexus<>::Disable();
    for (auto& File : MvsFileList)
        Nexus<>::AddTask(The, &Core::ScanFile, File);
    Nexus<>::Enable();
    Nexus<>::WaitAll();
    Rescue();
}

void Core::SingleCoreScan()
{
    Begin();
    MvsFileList = RA::OS::Dir(MoOption.MsDirectory, 'r', 'f');

    Filter();
    (Color::Cyan << "Files in Dir: " << MvsFileList.size() << Color::Mod::Reset).Print();

    MvoFiles.clear();
    MvoFiles.CreateMTX();
    Nexus<>::Disable();
    for (auto& File : MvsFileList)
        The.ScanFile(File);
    Nexus<>::Enable();
    Nexus<>::WaitAll();
    Rescue();
}

void Core::Print()
{
    Begin();
    if (MoFilePtr != nullptr)
    {
        GET(MoFile);
        MoFile.Print();
        return;
    }

    if (MoOption.MbModify)
    {
        RA::OS OS;
        for (const xp<File> TargetPtr : MvoFiles) // open file for modification
        { 
            GSS(Target);
            if (Target.MbMatches) 
            {
                try {
                    OS.RunConsoleCommand("subl " + Target.MsPath);
                }
                catch (std::runtime_error& err) {
                    printf("%s\n", err.what());
                }
            }
        }
    }

    if (MoOption.MbOnlyNameFiles) // print what the user was looking for
    {
        The.PrintDivider();
        bool LbMatchFound = false;
        for (xp<File>& TargetPtr : MvoFiles)
        {
            GSS(Target);
            if (Target.MbBinary || Target.MsError.size())
                continue;
            if (Target.MbMatches) {
                Target.MsPath.InSub('\\', "\\\\").Print();
                LbMatchFound = true;
            }
        }
        if (!LbMatchFound)
            printf("No Matches Found\n");
    }
    else {
        for (xp<File>& TargetPtr : MvoFiles)
        {
            GSS(Target);
            if (Target.MbBinary || Target.MsError.size())
                continue;
            Target.Print();
        };
    }

    The.PrintDivider();
    bool LbBinaryMatched = false;
    Nexus<>::WaitAll();
    for (xp<File>& TargetPtr : MvoFiles) // print binary names
    {
        GSS(Target);
        if (Target.MsError.Size())
            continue;

        if (Target.MbBinary && Target.MbMatches) {
            ("Binary File Matches: " + Target.MsPath.InSub('\\', "\\\\")).Print();
            LbBinaryMatched = true;
        }
    }
    if (LbBinaryMatched)
        The.PrintDivider();

    bool LbErrorMatched = false;
    if (MoOption.MoIncludeLockedFileErros)
    {
        for (const xp<File>& TargetPtr : MvoFiles) // print errors
        {
            GSS(Target);
            if (Target.MsError.Size()) {
                Target.MsError.Print();
                LbErrorMatched = true;
            }
        }
        if (LbErrorMatched)
            The.PrintDivider();
    }

    Rescue();
}

void Core::PrintDivider() const {
    xstring Out;
    Out += Color::Blue;
    Out += xstring(RA::OS::GetConsoleSize()[0], '-');
    Out += Color::Mod::Reset;
    Out.Print();
}
