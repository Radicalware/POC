#include "CPUCore.cuh"
#include "Timer.h"
#include "OS.h"
#include "Stats.cuh"
#include "Nexus.h"
#include "SYS.h"

CPU::Core::Core(const xstring& FsFilePath, const bool FbMultiCPU) : 
    APU::Core(FsFilePath), MbMultiCPU(FbMultiCPU)
{
}


void CPU::Core::ParseIndex(const xint FnCol)
{
    Begin();

    const auto& LvValues = MoHost.MvColumnValues[FnCol];
    auto& LoData = MoHost.MvSummaries[FnCol];

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
        const auto LnValMinusMean = LnValue - LoData.Mean;
        LoData.SumDeviation += (LnValMinusMean * LnValMinusMean);
        LoData.SD = std::sqrt(LoData.SumDeviation / static_cast<double>(LoData.Count));
    }

    if (LoData.Count != LvValues.Size())
        ThrowIt("Size Mismatch!!");

    LoData.Mean = LoData.Sum / static_cast<double>(LoData.Count);
    for (const auto& Val : LvValues)
    {
        const auto LnValMinusMean = Val - LoData.Mean;
        LoData.Variance += (LnValMinusMean * LnValMinusMean);
    }
    LoData.Variance /= static_cast<double>(LoData.Count);

    Rescue();
}

void CPU::Core::ParseForColumnSummary(const xint FnCol)
{
    Begin();
    auto& LoStats = MoHost.MvStatsCPU[FnCol];

    for (xint l = 0; l < SnReloop; l++)
    {
        for (xint Row = 0; Row < GetRowCount(); Row++)
            LoStats << MoHost.MvColumnValues[FnCol][Row];
    }

    MoHost.MvSummaries[FnCol].SetCPU(GetRowCount(), LoStats);
    Rescue();
}

void CPU::Core::ConfigureColumnValues()
{
    APU::Core::ConfigureColumnValues();
    MoHost.MvStatsCPU  = MKP<RA::StatsCPU[]>(GetColumnCount());
    MoHost.MvSummaries = MKP<ColumnSummary[]>(GetColumnCount());
    for (auto& LoStat : MoHost.MvStatsCPU)
        LoStat.Construct(0, SvStatArgs);
}

void CPU::Core::ParseResults(const bool FbForceRestart)
{
    Begin();

//#ifdef BxDebug
//    MbMultiCPU = false;
//#endif // BxDebug

    if (MbMultiCPU)
    {
        if (CliArgs.Has('j'))
        {
            auto LvThreads = xvector<xp<std::jthread>>();
            for (xint Col = 0; Col < GetColumnCount(); Col++)
                LvThreads << MKP<std::jthread>(std::bind(&CPU::Core::ParseForColumnSummary, std::ref(The), Col));
            LvThreads.EraseAll();
        }
        else
        {
            for (xint Col = 0; Col < GetColumnCount(); Col++)
                Nexus<>::AddTask(The, &CPU::Core::ParseForColumnSummary, Col);
            Nexus<>::WaitAll();
        }
    }
    else
    {
        for (xint Col = 0; Col < GetColumnCount(); Col++)
            ParseForColumnSummary(Col);
    }

    Rescue();
}
