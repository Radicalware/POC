#include "ColumnData.cuh"
#include "ImportCUDA.cuh"

#define CopyStatsToColumnSummary() \
    Count = FnCount; \
    Max = FoStats.STOCH().GetMax(); \
    Min = FoStats.STOCH().GetMin(); \
    Mean = FoStats.GetAVG(); \
    SD = FoStats.SD().GetDeviation(); \
    Sum = FoStats.AVG().GetSum();

void GPU::ColumnData::Initialize(const xvector<double>& FvRowValues)
{
    MvHostRows = FvRowValues.Ptr();
    MvDeviceRows = RA::Host::AllocateArrOnDevice(MvHostRows, RA::Allocate(FvRowValues.Size(), sizeof(double)));
}

std::ostream& operator<<(std::ostream& out, const ColumnSummary& FoData)
{
    out <<
        "Count: " << FoData.Count    << '\n' <<
        "Mean:  " << FoData.Mean     << '\n' <<
        "Sum :  " << FoData.Sum      << '\n' <<
        "SD:    " << FoData.SD       << '\n' <<
        "Min:   " << FoData.Min      << '\n' <<
        "Max:   " << FoData.Max      << '\n';
    return out;
}


bool ColumnSummary::operator==(const ColumnSummary& Other) const
{
    if (!RA::Appx(Mean, Other.Mean)) return false;
    if (!RA::Appx(Sum, Other.Sum)) return false;
    if (!RA::Appx(SD, Other.SD)) return false;
    if (!RA::Appx(Min, Other.Min)) return false;
    if (!RA::Appx(Max, Other.Max)) return false;
    return true;
}

DHF void ColumnSummary::SetCPU(const xint FnCount, const RA::StatsCPU& FoStats)
{
    CopyStatsToColumnSummary();
}

DDF void ColumnSummary::SetGPU(const xint FnCount, const RA::StatsGPU& FoStats)
{
    CopyStatsToColumnSummary();
}

#undef CopyStatsToColumnSummary