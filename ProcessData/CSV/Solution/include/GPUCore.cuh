#pragma once

#include "Macros.h"
#include "CudaBridge.cuh"
#include "StatsGPU.cuh"

#include "ColumnData.cuh"
#include "Core.cuh"

#include <tuple>

namespace GPU
{
    __global__ void ParseForColumnSummary(
        ColumnSummary* FvSummaries, // Output
        RA::StatsGPU* FvStats, const ColumnData* FvColumnData, // column data is processed through stats
        const xint FnColumnCount, const xint FnRowCount, // Dimensions for the data
        const xint FnReloop); 

    class Core : public APU::Core
    {
    public:
             Core(const xstring& FsFilePath);
        VIR ~Core();
        VIR void ConfigureColumnValues();
        VIR void ParseResults(const bool FbForceRestart);

    private:
        struct Device
        {
            ColumnData* MvColumnData = nullptr;
            RA::CudaBridge<RA::StatsGPU> MoResultStats;
            RA::CudaBridge<ColumnSummary> MoColumnSummaries;
        };
        Device MoDevice;
    };
}