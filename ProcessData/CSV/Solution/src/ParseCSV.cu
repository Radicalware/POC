﻿// Copyright[2021][Joel Leagues aka Scourge] under the Apache V2 Licence

#include "Macros.h"
#include "xmap.h"

#include "StatsGPU.cuh"
#include "CudaBridge.cuh"
#include "OS.h"
#include "Timer.h"

#include "GPUCore.cuh"
#include "CPUCore.cuh"
#include "SYS.h"

#include "vld.h"

using std::cout;
using std::endl;

RA::SYS Args;

void RetEarly(const char* Err)
{
    cout << Err << endl;
    EXIT();
}

void TestCPU();
void TestGPU();
xstring GetPath();

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

    if (Args.Has('c'))
        TestCPU();
    else if (Args.Has('g'))
        TestGPU();
    else if (!Args.Has('c') && !Args.Has('g'))
    {
        TestCPU();
        TestGPU();
    }

    FinalRescue();
    Nexus<>::Stop();
    return 0;
}

xstring GetPath()
{
    Begin();
    auto LsPath = xstring();
    if (Args.Has('p'))
        LsPath = Args.Key('p').First();
    else
        LsPath = "C:/Source/git/POC/ProcessData/CSV/Data.csv";

    if (!LsPath.Match(R"(^.*(\.csv)$)"))
        RetEarly("File must be a csv type");

    if (!RA::OS::HasFile(LsPath))
        RetEarly("Path not found");

    return LsPath;
    Rescue();
}

void TestAlgo(RA::Timer& FoTimer, APU::Core& FoCore)
{
    const auto LnMultiplierSize = (Args.Has('m') ? Args.Key('m').First().To64() : 1);
    FoCore.ReadData(LnMultiplierSize);
    FoCore.ConfigureColumnValues();

    FoTimer.Reset();
    FoCore.ParseResults();
    const auto LoSingleThreadData = FoCore.GetDataset(0);
    //LoTime.Reset();
    //FoCore.ParseThreadedResultsWtihCPU(true);
    //const auto LoMultiThreadData = FoCore.GetDataset(0);
    //cout << "Time Multi  Thread: " << LoTime.GetElapsedTimeMilliseconds() << endl;

    Rescue();
}

xint GetTargetIndex()
{
    xint LnIdx = 0;
    if (Args.Has('i'))
    {
        LnIdx = Args.Key('i').First().To64();
        cout << "Inspecting: " << LnIdx << endl;
    }
    return LnIdx;
}

void TestCPU()
{
    Begin();
    cout << "Running: " << __CLASS__ << '\n';

    const auto LbSingleGPU = Args.Has('s');
    const auto LbMultiGPU = !LbSingleGPU;
    xp<APU::Core> LoCorePtr = MKP<CPU::Core>(GetPath(), LbMultiGPU);
    GET(LoCore);
    auto LoTimer = RA::Timer();
    TestAlgo(LoTimer, LoCore);
    cout << "Time Single Thread CPU: " << LoTimer.GetElapsedTimeMilliseconds() << endl;

    auto LnIdx = GetTargetIndex();
    cout << LoCore.GetDataset(LnIdx) << endl;

    Rescue();
}

void TestGPU()
{
    Begin();
    cout << "Running: " << __CLASS__ << '\n';

    xp<APU::Core> LoCorePtr = MKP<GPU::Core>(GetPath());
    GET(LoCore);
    auto LoTimer = RA::Timer();
    TestAlgo(LoTimer, LoCore);
    cout << "Time Multi Thread GPU: " << LoTimer.GetElapsedTimeMilliseconds() << endl;

    auto LnIdx = GetTargetIndex();
    cout << LoCore.GetDataset(LnIdx) << endl;
    Rescue();
}