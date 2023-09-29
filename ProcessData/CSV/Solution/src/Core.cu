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

    if (MbRead)
        return;
    MbRead = true;
    MbParsed = false;

    auto LoTimer = RA::Timer();
    MoHost.MvCSVColumnValuesStr = RA::OS::ReadFile(MsFilePath)
        .Split('\n')
#ifdef BxDebug
        .ForEachThreadSeq<xvector<xstring>>([](const xstring& Str) { return Str.Split(','); });
#else // BxDebug
        .ForEachThreadUnseq<xvector<xstring>>([](const xstring& Str) { return Str.Split(','); });
#endif
    MoHost.MvCSVColumnValuesStr.Remove(0); // first row is just column value names
    for (xint i = 0; i < MoHost.MvCSVColumnValuesStr.Size(); )
    {
        if (!MoHost.MvCSVColumnValuesStr[i].Size())
            MoHost.MvCSVColumnValuesStr.Remove(i);
        else
            i++;
    }

    MnColumnCount = MoHost.MvCSVColumnValuesStr.At(0).Size();
    MnRowCount = MoHost.MvCSVColumnValuesStr.Size();
    MoHost.MvColumnValues.clear();
    Rescue();
}

#define CurrentCol (Col + (LnColumnLoop * MnColumnCount))
#define CurrentRow (Row + (LnRowLoop * MnRowCount))
void APU::Core::ConfigureColumnValues()
{
    Begin();
    if (MbParsed)
        return;
    MbParsed = true;
    for (xint i = 0; i < GetColumnCount(); i++)
        MvRange << i;

    const auto LnSize = MoHost.MvColumnValues.Size();


    MoHost.MvCSVColumnValues.Resize(MnRowCount);
    for (xint Row = 0; Row < MnRowCount; Row++)
    {
        MoHost.MvCSVColumnValues[Row].Resize(MnColumnCount);
        for (xint Col = 0; Col < MnColumnCount; Col++)
            MoHost.MvCSVColumnValues[Row][Col] = MoHost.MvCSVColumnValuesStr[Row][Col].ToDouble();
    }

    MoHost.MvColumnValues.Resize(GetColumnCount());
    for (auto LnColumnLoop = 0; LnColumnLoop < MnSizeMultiplier; LnColumnLoop++)
    {
        for (xint Col = 0; Col < MnColumnCount; Col++)
        {
            MoHost.MvColumnValues[CurrentCol].Resize(GetRowCount());
            for (auto LnRowLoop = 0; LnRowLoop < MnSizeMultiplier; LnRowLoop++)
            {
                for (xint Row = 0; Row < MnRowCount; Row++) // start at idx 1 because idx 0 is the row descriptors
                    MoHost.MvColumnValues[CurrentCol][CurrentRow]
                    = MoHost.MvCSVColumnValues[Row][Col];
            }
        }
    }

    Rescue();
}
#undef CurrentCol
#undef CurrentRow