#include "Core.cuh"
#include "Timer.h"
#include "OS.h"

APU::Core::Core(const xstring& FsFilePath): MsFilePath(FsFilePath)
{
}

void APU::Core::ReadData(const xint FnSizeMultiplier)
{
    Begin();
    MnSizeMultiplier = FnSizeMultiplier;
    MbParsed = false;
    auto LoTimer = RA::Timer();
    MoHost.MvColumnValuesStr = RA::OS::ReadFile(MsFilePath)
        .Split('\n')
#ifdef BxDebug
        .ForEachThreadSeq<xvector<xstring>>([](const xstring& Str) { return Str.Split(','); });
#else // BxDebug
        .ForEachThreadUnseq<xvector<xstring>>([](const xstring& Str) { return Str.Split(','); });
#endif
    MoHost.MvColumnValuesStr.Remove(0); // first row is just column value names
    for (xint i = 0; i < MoHost.MvColumnValuesStr.Size(); )
    {
        if (!MoHost.MvColumnValuesStr[i].Size())
            MoHost.MvColumnValuesStr.Remove(i);
        else
            i++;
    }

    MnColumnCount = MoHost.MvColumnValuesStr.At(0).Size();
    MnRowCount = MoHost.MvColumnValuesStr.Size();
    cout << "Time to read data MS: " << LoTimer.GetElapsedTimeMilliseconds() << endl;
    MoHost.MvColumnValues.clear();
    Rescue();
}


void APU::Core::ConfigureColumnValues()
{
    Begin();
    if (MbParsed)
        return;
    MbParsed = true;
    for (xint i = 0; i < GetColumnCount(); i++)
        MvRange << i;

    const auto LnSize = MoHost.MvColumnValues.Size();

    for (auto LnColumnLoop = 0; LnColumnLoop < MnSizeMultiplier; LnColumnLoop++)
    {
        for (xint Col = 0; Col < MnColumnCount; Col++)
        {
            MoHost.MvColumnValues << xvector<double>();
            for (auto LnRowLoop = 0; LnRowLoop < MnSizeMultiplier; LnRowLoop++)
                for (xint Row = 0; Row < MnRowCount; Row++) // start at idx 1 because idx 0 is the row descriptors
                    MoHost.MvColumnValues.Last() << MoHost.MvColumnValuesStr[Row][Col].ToDouble();
        }
    }

    Rescue();
}