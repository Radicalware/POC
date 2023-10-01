#pragma once

#include "Macros.h"

#include "Core.cuh"
#include "ColumnData.cuh"


namespace CPU
{
    class Core : public APU::Core
    {
    public:
        Core(const xstring& FsFilePath, const bool FbMultiCPU = true);

    private:
        void ParseIndex(const xint FnCol);
        void ParseForColumnSummary(const xint FnCol);
    public:
        VIR void ConfigureColumnValues();
        VIR void ParseResults(const bool FbForceRestart);

    private:
        bool MbMultiCPU = true;
    };
}