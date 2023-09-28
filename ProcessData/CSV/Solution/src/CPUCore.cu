#include "CPUCore.cuh"
#include "Timer.h"
#include "OS.h"
#include "Stats.cuh"
#include "Nexus.h"

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

void CPU::Core::ParseIndex(const xint FnCol, RA::StatsCPU& FoStat)
{
    Begin();
    for (xint Row = 0; Row < GetRowCount(); Row++)
        FoStat << MoHost.MvColumnValues[FnCol][Row];
    Rescue();
}

void CPU::Core::ParseResults(const bool FbForceRestart)
{
    Begin();

    if (!FbForceRestart)
        if (MbParsed && MoHost.MvSummaries.Size())
            return;

    MoHost.MvSummaries.clear();
    MoHost.MvSummaries.resize(GetColumnCount());

    const auto LmStatOps = xmap<RA::EStatOpt, xint>{ 
        {RA::EStatOpt::AVG, 0},{RA::EStatOpt::STOCH, 0},{RA::EStatOpt::SD, 0} 
    };
    const xint LnZero = 0;
    MoHost.MvStatsCPU = MKP<RA::StatsCPU[]>(GetColumnCount()/*, 0, LmStatOps*/);

    if (MbMultiCPU)
    {
        for (RA::StatsCPU& LoStat : MoHost.MvStatsCPU)
            Nexus<void>::AddTask(LoStat, &RA::StatsCPU::Construct, LnZero, LmStatOps, LnZero);

        MvRange.LoopAllUnseq(
            [this](const xint FnCol)
            { The.ParseIndex(FnCol, MoHost.MvStatsCPU[FnCol]); return false; }
        );

        MvRange.LoopAllUnseq([this](const xint FnCol)
            { The.MoHost.MvSummaries[FnCol].Set(GetRowCount(), MoHost.MvStatsCPU[FnCol]); }
        );
    }
    else
    {
        MoHost.MvStatsCPU.Proc([this, &LmStatOps](auto& LoStat) { LoStat.Construct(0, LmStatOps); });

        MvRange.Proc(
            [this](const xint FnCol)
            { The.ParseIndex(FnCol, MoHost.MvStatsCPU[FnCol]); return false; }
        );

        MvRange.Proc([this](const xint FnCol)
            { The.MoHost.MvSummaries[FnCol].Set(GetRowCount(), MoHost.MvStatsCPU[FnCol]); return false; }
        );
    }

    Rescue();
}


CST ColumnSummary& CPU::Core::GetDataset(const xint FnValue) CST
{
    Begin();
    return MoHost.MvSummaries[FnValue];
    Rescue();
}
