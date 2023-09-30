#pragma once

#include "Macros.h"
#include "CudaBridge.cuh"
#include "StatsGPU.cuh"

#include "ColumnData.cuh"
#include "Core.cuh"

#include <tuple>

namespace GPU
{
    __global__ void ParseResultColumnIdx(
        ColumnSummary* FvSummaries, // Output
        RA::StatsGPU* FvStats, const ColumnData* FvColumnData, // column data is processed through stats
        const xint FnColumnCount, const xint FnRowCount); // Dimensions for the data

    class Core : public APU::Core
    {
    public:
             Core(const xstring& FsFilePath);
        VIR ~Core();
        VIR void ConfigureColumnValues();
        VIR void ParseResults(const bool FbForceRestart);

        VIR CST ColumnSummary& GetDataset(const xint FnValue) CST;
    private:
        std::tuple<dim3, dim3> GetGridBlockConfig(const xint FnDbgVal = 0) const;
        struct Device
        {
            ColumnData* MvColumnData = nullptr;
            RA::CudaBridge<RA::StatsGPU> MoResultStats;
            RA::CudaBridge<ColumnSummary> MoColumnSummaries;
        };
        Device MoDevice;
    };
}