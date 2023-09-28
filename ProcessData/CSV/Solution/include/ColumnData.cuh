#pragma once

#include "Macros.h"
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


    TTT IXF void Set(const xint FnCount, const T& FoStats);
};

std::ostream& operator<<(std::ostream& out, const ColumnSummary& FoData);

TTT IXF void ColumnSummary::Set(const xint FnCount, const T& FoStats)
{
    Count = FnCount;
    Max = FoStats.STOCH().GetMax();
    Min = FoStats.STOCH().GetMin();
    Mean = FoStats.GetAVG();
    SD = FoStats.SD().GetDeviation();
    Variance = FoStats.SD().GetAvgOffset();
    Sum = FoStats.AVG().GetSum();
}

