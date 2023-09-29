// Copyright[2021][Joel Leagues aka Scourge] under the Apache V2 Licence

#include "Macros.h"
#include "xmap.h"

#include "StatsGPU.cuh"
#include "CudaBridge.cuh"
#include "OS.h"
#include "Timer.h"

#include "GPUCore.cuh"
#include "CPUCore.cuh"
#include "SYS.h"

#if BxDebug
#include "vld.h"
#endif

using std::cout;
using std::endl;

RA::SYS Args;

void ExitEarly(const char* Err)
{
    cout << Err << endl;
    EXIT();
}


class Test
{
public:
    istatic xstring SoPath;
public:

    istatic RA::Mutex SoMutex;
    istatic sp<APU::Core> SoCoreCPUPtr;
    istatic sp<APU::Core> SoCoreGPUPtr;

    istatic void Prep(const char* FsPlatform, APU::Core& FoCore);

    istatic void PrepCPU();
    istatic void PrepGPU();

    istatic void RunCPU();
    istatic void RunGPU();

    istatic void CheckValues();

    istatic xint GetTargetIndex();
    istatic void SetPath();
    istatic auto GetPath() { return SoPath; }
};

int main(int argc, char** argv)
{
    Begin();
    Nexus<>::Start();

    Args.AddAlias('p', "--Path");
    Args.AddAlias('i', "--Index");
    Args.AddAlias('c', "--TestCPU");
    Args.AddAlias('g', "--TestGPU");
    Args.AddAlias('m', "--Multiplier");
    Args.AddAlias('s', "--SingleCPU");

    Args.SetArgs(argc, argv);

    bool LbParseCPU = Args.Has('c');
    bool LbParseGPU = Args.Has('g');
    if (!LbParseCPU && !LbParseGPU)
    {
        LbParseCPU = true;
        LbParseGPU = true;
    }

#ifdef BxDebug
    //LbParseCPU = true;  // true, false
    //LbParseGPU = false; // true, false
#endif

    Test::SetPath();
    if (LbParseCPU)
#if BxDebug
        Test::PrepCPU();
#else
        Nexus<void>::AddTask(&Test::PrepCPU);
#endif
    if (LbParseGPU)
#if BxDebug
        Test::PrepGPU();
#else
        Nexus<void>::AddTask(&Test::PrepGPU);
#endif
    if (!LbParseCPU && !LbParseGPU)
        ExitEarly("No Selection");
    Nexus<void>::WaitAll();
    cout << "\n\n";

    if (LbParseCPU)
        Test::RunCPU();
    if (LbParseGPU)
        Test::RunGPU();

    if (LbParseCPU && LbParseGPU)
        Test::CheckValues();

    FinalRescue();
    Nexus<>::Stop();
    return 0;
}

void Test::SetPath()
{
    Begin();
    SoPath = xstring();
    if (Args.Has('p'))
        SoPath = Args.Key('p').First();
#if BxDebug
    else
        SoPath = "C:/Source/git/POC/ProcessData/CSV/Data.csv";
#endif

    if (!SoPath.Match(R"(^.*(\.csv)$)"))
        ExitEarly("File must be a csv type");

    if (!RA::OS::HasFile(SoPath))
        ExitEarly("Path not found");

    Rescue();
}

void Test::Prep(const char* FsPlatform, APU::Core& FoCore)
{
    auto LoTimer = RA::Timer();
    const auto LnMultiplierSize = (Args.Has('m') ? Args.Key('m').First().To64() : 1);
    FoCore.ReadData(LnMultiplierSize);
    {
        Test::SoMutex.Wait();
        auto LoLock = Test::SoMutex.CreateLock();
        cout << FsPlatform << "Read Data Sec: " << RA::FormatNum(LoTimer.GetElapsedTimeSeconds()) << endl;

    }

    LoTimer.Reset();
    FoCore.ConfigureColumnValues();
    {
        Test::SoMutex.Wait();
        auto LoLock = Test::SoMutex.CreateLock();
        cout << FsPlatform << "Config Data Sec: " << RA::FormatNum(LoTimer.GetElapsedTimeSeconds()) << endl;

    }
}

void Test::PrepCPU()
{
    const auto LbSingleCPU = Args.Has('s');
    const auto LbMultiCPU = !LbSingleCPU;
    SoCoreCPUPtr = MKP<CPU::Core>(SoPath, LbMultiCPU);
    GET(SoCoreCPU);
    Test::Prep("CPU", SoCoreCPU);
}

void Test::PrepGPU()
{
    SoCoreGPUPtr = MKP<GPU::Core>(SoPath);
    GET(SoCoreGPU);
    Test::Prep("GPU", SoCoreGPU);
}

xint Test::GetTargetIndex()
{
    xint LnIdx = 0;
    if (Args.Has('i'))
    {
        LnIdx = Args.Key('i').First().To64();
        cout << "Inspecting: " << LnIdx << endl;
    }
    return LnIdx;
}

void Test::RunCPU()
{
    Begin();
    cout << "Running: " << __CLASS__ << '\n';
    
    GET(SoCoreCPU);
    auto LoTimer = RA::Timer();
    SoCoreCPU.ParseResults();

    const auto LbSingleCPU = Args.Has('s');
    if (LbSingleCPU)
    {
        cout << "Time Single Thread CPU Sec: " << RA::FormatNum(LoTimer.GetElapsedTimeSeconds()) << endl;
        cout << "Time Single Thread CPU MS : " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;
    }
    else
    {
        cout << "Time Multi Thread CPU Sec: " << RA::FormatNum(LoTimer.GetElapsedTimeSeconds()) << endl;
        cout << "Time Multi Thread CPU MS : " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;
    }

    auto LnIdx = GetTargetIndex();
    cout << SoCoreCPU.GetDataset(LnIdx) << endl;

    Rescue();
}

void Test::RunGPU()
{
    Begin();
    cout << "Running: " << __CLASS__ << '\n';

    GET(SoCoreGPU);
    auto LoTimer = RA::Timer();
    SoCoreGPU.ParseResults();
    cout << "Time Multi Thread GPU Sec: " << RA::FormatNum(LoTimer.GetElapsedTimeSeconds()) << endl;
    cout << "Time Multi Thread GPU MS : " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;

    auto LnIdx = GetTargetIndex();
    cout << SoCoreGPU.GetDataset(LnIdx) << endl;
    Rescue();
}

void Test::CheckValues()
{
    Begin();
    GET(SoCoreCPU);
    GET(SoCoreGPU);

    if (SoCoreCPU.GetColumnCount() != SoCoreGPU.GetColumnCount())
        ThrowIt("Bad Col Count: ", SoCoreCPU.GetColumnCount(), " != ", SoCoreGPU.GetColumnCount());
    if (SoCoreCPU.GetRowCount() != SoCoreGPU.GetRowCount())
        ThrowIt("Bad Col Count: ", SoCoreCPU.GetRowCount(), " != ", SoCoreGPU.GetRowCount());

    const auto LnColCount = SoCoreGPU.GetColumnCount();

    auto LbBadTest = false;
    for (xint Col = 0; Col < LnColCount; Col++)
    {
        if (SoCoreCPU.GetDataset(Col) != SoCoreGPU.GetDataset(Col))
        {
            LbBadTest = true;
            cout << "Bad Case Idx: " << Col << endl;
            cout << "CPU ------------------------" << endl;
            cout << SoCoreCPU.GetDataset(Col) << endl;
            cout << "GPU ------------------------" << endl;
            cout << SoCoreGPU.GetDataset(Col) << endl;
        }
    }

    if (!LbBadTest)
        cout << "\nNo Bad Checks!!\n\n";

    Rescue();
}
