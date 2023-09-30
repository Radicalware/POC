#include "GPUCore.cuh"
#include "Timer.h"
#include "OS.h"
#include "CudaBridge.cuh"

#include <cmath>

__global__ void GPU::ParseResultColumnIdx(
    ColumnSummary* FvSummaries, 
    RA::StatsGPU* FvStats, const ColumnData* FvColumnData, 
    const xint FnColumnCount, const xint FnRowCount)
{
    auto Col = RA::Device::GetThreadID();
    if (Col >= FnColumnCount)
        return;
    
    const auto& LvColumnValues = FvColumnData[Col];
    auto& LoStats = FvStats[Col];
    auto& LoSummary = FvSummaries[Col];

    for (xint i = 0; i < FnRowCount; i++)
        LoStats << LvColumnValues.MvDeviceRows[i];
    
    LoSummary.SetGPU(FnRowCount, LoStats);
}

GPU::Core::Core(const xstring& FsFilePath): APU::Core(FsFilePath)
{
    const auto [LnGrid, LnBlock] = GetGridBlockConfig(20000);
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

    Rescue();
}

void GPU::Core::ParseResults(const bool FbForceRestart)
{
    Begin();
    if(!FbForceRestart)
        if (MbParsed && MoDevice.MoResultStats.Size())
            return;

    const auto LnRetAllocate = RA::Allocate(GetColumnCount(), sizeof(ColumnData));
    const auto LmStatOps = xmap<RA::EStatOpt, xint>{
        {RA::EStatOpt::AVG, 0},{RA::EStatOpt::STOCH, 0},{RA::EStatOpt::SD, 0}
    };

    MoHost.MvStatsGPU = MKP<RA::StatsGPU[]>(GetColumnCount());
    for (auto& LoStat : MoHost.MvStatsGPU)
        LoStat.Construct(0, LmStatOps);

    MoDevice.MoResultStats = RA::CudaBridge<RA::StatsGPU>(MoHost.MvStatsGPU, MoHost.MvStatsGPU.GetLength());
    MoDevice.MoResultStats.AllocateHost();
    MoDevice.MoResultStats.AllocateDevice();
    MoDevice.MoResultStats.CopyHostToDeviceAsync();
    MoDevice.MoResultStats.SyncStream();

    //const auto [LnGrid, LnBlock] = RA::Host::GetDimensions3D(GetColumnCount());
    cout << "Column Count: " << GetColumnCount() << endl;
    const auto [LnGrid, LnBlock] = GetGridBlockConfig();
    

    MoDevice.MoColumnSummaries = RA::CudaBridge<ColumnSummary>::ARRAY::RunGPU(
        RA::Allocate(GetColumnCount(), sizeof(ColumnSummary)),
        LnGrid, LnBlock,
        &GPU::ParseResultColumnIdx,
        MoDevice.MoResultStats.GetDevice(),
        MoDevice.MvColumnData, GetColumnCount(), GetRowCount()
    );
    MoDevice.MoColumnSummaries.SyncStream();
    MoDevice.MoColumnSummaries.CopyDeviceToHost();
    MoDevice.MoColumnSummaries.SyncAll();

    Rescue();
}

std::tuple<dim3, dim3> GPU::Core::GetGridBlockConfig(const xint FnDbgVal) const
{
    const auto LnColumnCount = (FnDbgVal) ? FnDbgVal : GetColumnCount();
    auto LnDown6 = RA::Pow(LnColumnCount, 1.0 / 6.0);
    while (RA::Pow(LnDown6, 6.0) < LnColumnCount)
        LnDown6++;

    const auto LnTarget = RA::Pow(LnDown6, 3.0);
    auto LnDown3 = RA::Pow(LnTarget, 1.0 / 3.0);
    while (RA::Pow(LnDown3, 3.0) < LnTarget)
        LnDown3++;

    auto LnGrid = dim3(LnDown6, LnDown6, LnDown6);

    auto LnX = LnDown3;
    auto LnY = LnDown3;
    auto LnZ = LnDown3;

    // find min block
    while ((pow(LnDown6, 3) * LnX * LnY * LnZ) > LnColumnCount)
    {
        if (LnY >= LnZ)
            LnZ--;
        else if (LnX >= LnY)
            LnY--;
        else
            LnX--;
    }
    // increase to hold enough values
    while (
        ((pow(LnDown6, 3) * LnX * LnY * LnZ) < LnColumnCount) 
        || ((LnX * LnY * LnZ) % 32 != 0))
    {
        if (LnY >= LnX)
            LnX++;
        else if (LnY >= LnZ)
            LnY++;
        else
            LnZ++;
    }
    auto LnBlock = dim3(LnX, LnY, LnZ);

    LnX = LnDown3;
    LnY = LnDown3;
    LnZ = LnDown3;
    while ((LnBlock.x * LnBlock.y * LnBlock.z * LnX * LnY * LnZ) > LnColumnCount)
    {
        if (LnY >= LnZ)
            LnZ--;
        else if (LnX >= LnY)
            LnY--;
        else
            LnX--;
    }
    while (
        ((LnBlock.x * LnBlock.y * LnBlock.z * LnX * LnY * LnZ) < LnColumnCount)
        /*|| ((LnX * LnY * LnZ) % 32 != 0)*/)
    {
        if (LnY >= LnX)
            LnX++;
        else if (LnY >= LnZ)
            LnY++;
        else
            LnZ++;
    }
    LnGrid.x = LnX;
    LnGrid.y = LnY;
    LnGrid.z = LnZ;


    RA::Print("Grid/Block: ",
        "(", LnGrid.x, ',', LnGrid.y, ',', LnGrid.z, ")",
        "(", LnBlock.x, ',', LnBlock.y, ',', LnBlock.z, ")");

    return std::make_tuple(LnGrid, LnBlock);
}

CST ColumnSummary& GPU::Core::GetDataset(const xint FnValue) CST
{ 
    Begin();
    return MoDevice.MoColumnSummaries[FnValue]; 
    Rescue();
}