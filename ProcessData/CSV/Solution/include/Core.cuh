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

            xstring ReadData(const xint FnSizeMultiplier = 1);
        VIR void ConfigureColumnValues();
        VIR void ParseResults(const bool FbForceRestart = false) = 0;

            auto GetColumnCount() const { return MnColumnCount * MnColMultiplier; }
            auto GetRowCount()    const { return MnRowCount * MnRowMultiplier; }

        CST ColumnSummary& GetColumnSummary(const xint FnValue) CST;

        istatic xint SnReloop = 1;

    protected:
        struct Host
        {
            xvector<xvector<xstring>> MvCSVColumnValuesStr; // From the CSV file
            xvector<xvector<double>>  MvCSVColumnValues;
            xvector<xvector<double>>  MvColumnValues; // converted

            xp<ColumnSummary[]>       MvSummaries; // converted

            xp<RA::StatsGPU[]>        MvStatsGPU;
            xp<RA::StatsCPU[]>        MvStatsCPU;

            GPU::ColumnData*          MvColumnData = nullptr;
        };
        Host MoHost;

        xstring MsFilePath;
        xint    MnColMultiplier = 1;
        xint    MnRowMultiplier = 1;
        xint    MnColumnCount = 0;
        xint    MnRowCount = 0;
        bool MbRead = false;
        bool MbParsed = false;

        const istatic xvector<RA::EStatOpt> SvStatArgs {RA::EStatOpt::AVG, RA::EStatOpt::STOCH, RA::EStatOpt::SD};
    };
}