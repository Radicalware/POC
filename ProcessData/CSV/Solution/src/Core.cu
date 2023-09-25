#include "Core.cuh"
#include "Timer.h"
#include "OS.h"

std::ostream& operator<<(std::ostream& out, const ColumnData& FoData)
{
    out <<
        "Count: " << FoData.Count    << '\n' <<
        "Mean:  " << FoData.Mean     << '\n' <<
        "Sum :  " << FoData.Sum      << '\n' <<
        "SD:    " << FoData.SD       << '\n' <<
        "Vrc:   " << FoData.Variance << '\n' <<
        "Min:   " << FoData.Min      << '\n' <<
        "Max:   " << FoData.Max      << '\n';
    return out;
}

Core::Core(const xstring& FsFilePath): MsFilePath(FsFilePath)
{
}

void Core::ReadData()
{
    Begin();
    MbParsed = false;
    auto LoTimer = RA::Timer();
    MvColumnValuesStr = RA::OS::ReadFile(MsFilePath)
        .Split('\n')
#ifdef BxDebug
        .ForEachThreadSeq<xvector<xstring>>([](const xstring& Str) { return Str.Split(','); });
#else // BxDebug
        .ForEachThreadSeq<xvector<xstring>>([](const xstring& Str) { return Str.Split(','); });
#endif
    MnColumnCount = MvColumnValuesStr.At(0).Size();
    cout << "Time to read data MS: " << LoTimer.GetElapsedTimeMilliseconds() << endl;
    MvColumnValues.clear();
    Rescue();
}

void Core::ConfigureColumnValues()
{
    Begin();
    if (MbParsed)
        return;
    MbParsed = true;
    MvBlankRow.clear();
    for (xint i = 0; i < MnColumnCount; i++)
    {
        MvBlankRow << 0;
        MvRange << i;
    }

    const auto LnSize = MvColumnValues.Size();
    for (xint Col = 0; Col < MnColumnCount; Col++)
    {
        MvColumnValues << xvector<double>();
        for (xint Row = 1; Row < MvColumnValuesStr.Size(); Row++) // start at idx 1 because idx 0 is the row descriptors
            if(MvColumnValuesStr[Row].Size()) // row of size 0 occurse at the EOF
                MvColumnValues.Last() << MvColumnValuesStr[Row][Col].ToDouble();
    }
    Rescue();
}

void Core::ParseResultColumnIdx(const xint Col)
{
    Begin();
    auto& LoData = MvResultData[Col];
    const auto& LvValues = MvColumnValues[Col];

    //LoData.Count = LValues.Size();
    LoData.Count = 1;

    LoData.Min = LvValues[0];
    LoData.Max = LvValues[0];
    LoData.Sum = LvValues[0];
    for (xint i = 1; i < LvValues.Size(); i++)
    {
        LoData.Count++;
        const auto& LnValue = LvValues[i];
        const auto& LnLastValue = LvValues[i - 1];
        if (LoData.Max < LnValue)
            LoData.Max = LnValue;
        if (LoData.Min > LnValue)
            LoData.Min = LnValue;
        LoData.Sum += LnValue;

        LoData.Mean = ((LoData.Mean * LoData.Count) + LnValue) / (LoData.Count + 1);
        LoData.SumDeviation += std::pow((LnValue - LoData.Mean), 2);
        LoData.SD = std::sqrt(LoData.SumDeviation / static_cast<double>(LoData.Count));
    }

    if (LoData.Count != LvValues.Size())
        ThrowIt("Size Mismatch!!");

    LoData.Mean = LoData.Sum / static_cast<double>(LoData.Count);
    for (const auto& Val : LvValues)
        LoData.Variance += std::pow((Val - LoData.Mean), 2);
    LoData.Variance /= static_cast<double>(LoData.Count);
    Rescue();
}

void Core::ParseResultsWtihCPU()
{
    Begin();
    if (MbParsed && MvResultData.Size())
        return;
    MvResultData.clear();
    for (xint i = 0; i < MnColumnCount; i++)
        MvResultData << ColumnData();

    for (xint Col = 0; Col < MnColumnCount; Col++)
        ParseResultColumnIdx(Col);

    Rescue();
}

void Core::ParseThreadedResultsWtihCPU(const bool FbForceRestart)
{
    Begin();

    if(!FbForceRestart)
        if (MbParsed && MvResultData.Size())
            return;

    MvResultData.clear();
    for (xint i = 0; i < MnColumnCount; i++)
        MvResultData << ColumnData();

    MvRange.LoopAllUnseq([this](const xint Idx) { The.ParseResultColumnIdx(Idx); });

    Rescue();
}
