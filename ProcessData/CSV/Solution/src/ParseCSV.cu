// Copyright[2021][Joel Leagues aka Scourge] under the Apache V2 Licence

#include "Macros.h"
#include "CudaBridge.cuh"
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

    class Timers
    {
    public:
        istatic double SnLoadGPUVals = 0;
        istatic double SnLoadCPUVals = 0;

        istatic double SnParseGPU = 0;
        istatic double SnParseCPU = 0;
    };

    istatic bool SbPrintedDim = false;
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

//  -p .\Data.csv -m 1000 -r 800

int main(int argc, char** argv)
{
    Begin();
    Nexus<>::Start();
    RA::CudaBridge<>::SyncAll();

    CliArgs.AddAlias('p', "--Path");
    CliArgs.AddAlias('i', "--Index");
    CliArgs.AddAlias('c', "--TestCPU");
    CliArgs.AddAlias('g', "--TestGPU");
    CliArgs.AddAlias('m', "--Multiplier");
    CliArgs.AddAlias('s', "--SingleCPU");
    CliArgs.AddAlias('r', "--RowLock");
    CliArgs.AddAlias('a', "--Assert");
    CliArgs.AddAlias('j', "--jThread");
    CliArgs.AddAlias('l', "--Loop");

    CliArgs.SetArgs(argc, argv);

    bool LbParseCPU = CliArgs.Has('c');
    bool LbParseGPU = CliArgs.Has('g');
    if (!LbParseCPU && !LbParseGPU)
    {
        LbParseCPU = true;
        LbParseGPU = true;
    }

    const bool LbTestBoth = (LbParseCPU && LbParseGPU);

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


    if (CliArgs.Has('l'))
        APU::Core::SnReloop = CliArgs.Key('l').First().To64();

    Nexus<void>::WaitAll();
    cout << "\n\n";

    if (LbTestBoth)
    {
        cout << "CPU/GPU Load Time: "
            << RA::FormatNum(Test::Timers::SnLoadCPUVals / Test::Timers::SnLoadGPUVals, 4) << endl;
        cout << "GPU/CPU Load Time: "
            << RA::FormatNum(Test::Timers::SnLoadGPUVals / Test::Timers::SnLoadCPUVals, 4) << endl;
        cout << "\n\n";
    }

    if (LbParseCPU)
        Test::RunCPU();
    if (LbParseGPU)
        Test::RunGPU();

    if (LbTestBoth)
    {
        cout << "CPU/GPU  Run  Time: "
            << RA::FormatNum(Test::Timers::SnParseCPU / Test::Timers::SnParseGPU, 4) << endl;
        cout << "CPU/GPU Total Time: "
            << RA::FormatNum((Test::Timers::SnLoadCPUVals + Test::Timers::SnParseCPU) 
                / (Test::Timers::SnLoadGPUVals + Test::Timers::SnParseGPU), 4) << endl;
        cout << "\n\n";
    }

    auto LbCheckVals = CliArgs.Has('a');
    #if BxDebug
        LbCheckVals = true;
    #endif
    if (LbCheckVals && LbTestBoth)
        Test::CheckValues();

    FinalRescue();
    Nexus<>::Stop();
    return 0;
}

void Test::SetPath()
{
    Begin();
    SoPath = xstring();
    if (CliArgs.Has('p'))
        SoPath = CliArgs.Key('p').First();
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
    const auto LnMultiplierSize = (CliArgs.Has('m') ? CliArgs.Key('m').First().To64() : 1);
    xstring LsColumnRowFormat = FoCore.ReadData(LnMultiplierSize);
    {
        Test::SoMutex.Wait();
        auto LoLock = Test::SoMutex.CreateLock();
        if(!SbPrintedDim)
            LsColumnRowFormat.Print();
        SbPrintedDim = true;
        cout << FsPlatform << "Read Data MS: " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;

    }

    LoTimer.Reset();
    FoCore.ConfigureColumnValues();
    {
        Test::SoMutex.Wait();
        auto LoLock = Test::SoMutex.CreateLock();
        cout << FsPlatform << "Config Data MS: " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;

    }
}

void Test::PrepCPU()
{
    const auto LbSingleCPU = CliArgs.Has('s');
    const auto LbMultiCPU = !LbSingleCPU;
    SoCoreCPUPtr = MKP<CPU::Core>(SoPath, LbMultiCPU);
    GET(SoCoreCPU);
    auto LoTimer = RA::Timer();
    Test::Prep("CPU", SoCoreCPU);
    Timers::SnLoadCPUVals = LoTimer.GetElapsedTimeMilliseconds();
}

void Test::PrepGPU()
{
    SoCoreGPUPtr = MKP<GPU::Core>(SoPath);
    GET(SoCoreGPU);
    auto LoTimer = RA::Timer();
    Test::Prep("GPU", SoCoreGPU);
    RA::CudaBridge<>::SyncAll();
    Timers::SnLoadGPUVals = LoTimer.GetElapsedTimeMilliseconds();
}

xint Test::GetTargetIndex()
{
    xint LnIdx = 0;
    if (CliArgs.Has('i'))
    {
        LnIdx = CliArgs.Key('i').First().To64();
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
    Timers::SnParseCPU = LoTimer.GetElapsedTimeMicroseconds();
    const auto LbSingleCPU = CliArgs.Has('s');
    if (LbSingleCPU)
        cout << "Time Single Thread CPU MS : " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;
    else
        cout << "Time Multi Thread CPU MS : " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;

    auto LnIdx = GetTargetIndex();
    cout << SoCoreCPU.GetColumnSummary(LnIdx) << endl;

    Rescue();
}

void Test::RunGPU()
{
    Begin();
    cout << "Running: " << __CLASS__ << '\n';

    GET(SoCoreGPU);
    auto LoTimer = RA::Timer();
    SoCoreGPU.ParseResults();
    Timers::SnParseGPU = LoTimer.GetElapsedTimeMicroseconds();
    cout << "Time Multi Thread GPU MS : " << RA::FormatNum(LoTimer.GetElapsedTimeMilliseconds()) << endl;

    auto LnIdx = GetTargetIndex();
    cout << SoCoreGPU.GetColumnSummary(LnIdx) << endl;
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
        if (SoCoreCPU.GetColumnSummary(Col) != SoCoreGPU.GetColumnSummary(Col))
        {
            LbBadTest = true;
            cout << "Bad Case Idx: " << Col << endl;
            cout << "CPU ------------------------" << endl;
            cout << SoCoreCPU.GetColumnSummary(Col) << endl;
            cout << "GPU ------------------------" << endl;
            cout << SoCoreGPU.GetColumnSummary(Col) << endl;
        }
    }

    if (!LbBadTest)
        cout << "No Bad Checks!!\n\n";

    Rescue();
}
