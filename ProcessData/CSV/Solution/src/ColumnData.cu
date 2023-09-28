#include "ColumnData.cuh"
#include "ImportCUDA.cuh"

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
        "Vrc:   " << FoData.Variance << '\n' <<
        "Min:   " << FoData.Min      << '\n' <<
        "Max:   " << FoData.Max      << '\n';
    return out;
}