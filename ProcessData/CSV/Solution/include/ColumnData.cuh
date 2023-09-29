#pragma once

#include "Macros.h"
#include "StatsCPU.cuh"
#include "StatsGPU.cuh"

namespace GPU
{
    struct ColumnData
    {
        const double* MvHostRows = nullptr;
        double* MvDeviceRows = nullptr;
        ColumnData() {};
        void Initialize(const xvector<double>& FvRowValues);
    };
}

struct ColumnSummary
{
    xint   Count = 0;
    double Mean = 0;
    double SD = 0;
    double SumDeviation = 0;
    double Variance = 0;
    double Min = 0;
    double Max = 0;
    double Sum = 0;

    bool operator==(const ColumnSummary& Other) const;

    // Method works but gives warnings
    // TTT IXF void Set(const xint FnCount, const T& FoStats);

    DHF void SetCPU(const xint FnCount, const RA::StatsCPU& FoStats);
    DDF void SetGPU(const xint FnCount, const RA::StatsGPU& FoStats);
};

std::ostream& operator<<(std::ostream& out, const ColumnSummary& FoData);

//TTT IXF void ColumnSummary::Set(const xint FnCount, const T& FoStats)
//{
//    CopyStatsToColumnSummary();
//}
