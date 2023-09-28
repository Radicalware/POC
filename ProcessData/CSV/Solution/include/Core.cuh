#pragma once

#include "Macros.h"
#include "CudaBridge.cuh"
#include "StatsGPU.cuh"
#include "StatsCPU.cuh"

#include "ColumnData.cuh"

namespace APU
{
    class Core
    {
    public:
                 Core(const xstring& FsFilePath);
        RIN void SetFilePath(const xstring& FsPath) { MsFilePath = FsPath; }

            void ReadData(const xint FnSizeMultiplier = 1);
        VIR void ConfigureColumnValues();
        VIR void ParseResults(const bool FbForceRestart = false) = 0;

            auto GetColumnCount() const { return MnColumnCount * MnSizeMultiplier; }
            auto GetRowCount()    const { return MnRowCount * MnSizeMultiplier; }

        VIR CST ColumnSummary& GetDataset(const xint FnValue) const = 0;

    protected:
        struct Host
        {
            xvector<xvector<xstring>> MvColumnValuesStr; // From the CSV file
            xvector<xvector<double>>  MvColumnValues; // converted

            xvector<ColumnSummary>    MvSummaries; // converted

            xp<RA::StatsGPU[]>        MvStatsGPU;
            xp<RA::StatsCPU[]>        MvStatsCPU;

            GPU::ColumnData*          MvColumnData = nullptr;
        };
        Host MoHost;

        xstring MsFilePath;
        xint    MnSizeMultiplier = 1;
        xint    MnColumnCount = 0;
        xint    MnRowCount = 0;
        xvector<xint> MvRange;
        bool MbParsed = false;
    };
}