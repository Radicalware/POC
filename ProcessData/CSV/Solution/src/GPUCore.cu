#include "GPUCore.cuh"
#include "Timer.h"
#include "OS.h"
#include "CudaBridge.cuh"


__global__ void GPU::ParseForColumnSummary(
    ColumnSummary* FvSummaries, 
    RA::StatsGPU* FvStats, const ColumnData* FvColumnData, 
    const xint FnColumnCount, const xint FnRowCount,
    const xint FnReloop)
{
    auto Col = RA::Device::GetThreadID();
    if (Col >= FnColumnCount)
        return;
    
    const auto& LvColumnValues = FvColumnData[Col];
    auto& LoStats = FvStats[Col];

    for (xint l = 0; l < FnReloop; l++)
    {
        for (xint i = 0; i < FnRowCount; i++)
            LoStats << LvColumnValues.MvDeviceRows[i];
    }
    
    FvSummaries[Col].SetGPU(FnRowCount, LoStats);
}

GPU::Core::Core(const xstring& FsFilePath): APU::Core(FsFilePath)
{
}

GPU::Core::~Core()
{
    HostDelete(MoHost.MvColumnData);
}

void GPU::Core::ConfigureColumnValues()
{
    Begin();
    APU::Core::ConfigureColumnValues();

    MoHost.MvColumnData = new ColumnData[GetColumnCount()];
    for (xint Col = 0; Col < GetColumnCount(); Col++)
        MoHost.MvColumnData[Col].Initialize(MoHost.MvColumnValues[Col]);

    MoDevice.MvColumnData = 
        RA::Host::AllocateArrOnDevice<ColumnData>(
        MoHost.MvColumnData, RA::Allocate(GetColumnCount(), 
            sizeof(ColumnData)));


    MoHost.MvStatsGPU = MKP<RA::StatsGPU[]>(GetColumnCount());
    for (auto& LoStat : MoHost.MvStatsGPU)
        LoStat.Construct(0, SvStatArgs);

    Rescue();
}

void GPU::Core::ParseResults(const bool FbForceRestart)
{
    Begin();

    MoDevice.MoResultStats = RA::CudaBridge<RA::StatsGPU>(MoHost.MvStatsGPU, MoHost.MvStatsGPU.GetLength());
    MoDevice.MoResultStats.AllocateDevice();
    MoDevice.MoResultStats.CopyHostToDeviceAsync();
    MoDevice.MoResultStats.SyncStream();

    cout << "Column Count: " << RA::FormatNum(GetColumnCount()) << endl;
    const auto [LvGrid, LvBlock] = RA::Host::GetDimensions3D(GetColumnCount());
    
    SetCudaMaxMem(GPU::ParseForColumnSummary);
    RA::Host::PrintGridBlockDims(LvGrid, LvBlock);
    MoDevice.MoColumnSummaries = RA::CudaBridge<ColumnSummary>::ARRAY::RunGPU(
        RA::Allocate(GetColumnCount(), sizeof(ColumnSummary)),
        LvGrid, LvBlock,
        &GPU::ParseForColumnSummary,
        MoDevice.MoResultStats.GetDevice(),
        MoDevice.MvColumnData, GetColumnCount(), GetRowCount(),
        SnReloop
    );
    MoDevice.MoColumnSummaries.SyncStream();
    MoDevice.MoColumnSummaries.CopyDeviceToHost();
    MoDevice.MoColumnSummaries.SyncAll();

    MoHost.MvSummaries = MoDevice.MoColumnSummaries.GetShared();

    Rescue();
}
