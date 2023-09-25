// Copyright[2021][Joel Leagues aka Scourge] under the Apache V2 Licence

#include "Macros.h"
#include "xmap.h"

#include "StatsGPU.cuh"
#include "CudaBridge.cuh"
#include "OS.h"
#include "Timer.h"

#include "Core.cuh"
#include "SYS.h"

// #include "vld.h"

using std::cout;
using std::endl;

RA::SYS Args;

void RetEarly(const char* Err)
{
    cout << Err << endl;
    EXIT();
}

int main(int argc, char** argv)
{
    Begin();
    Nexus<>::Start();

    Args.AddAlias('p', "--Path");
    Args.AddAlias('i', "--Index");
    Args.SetArgs(argc, argv);

    auto LsPath = xstring();
    if (Args.Has('p'))
        LsPath = Args.Key('p').First();
    else
        LsPath = "C:/Source/Study/CodingChallenges/Contracts/Amazon/Robotics/Data.csv";

    if (!LsPath.Match(R"(^.*(\.csv)$)"))
        RetEarly("File must be a csv type");

    if (!RA::OS::HasFile(LsPath))
        RetEarly("Path not found");

    auto LoCore = Core(LsPath);
    LoCore.ReadData();
    LoCore.ConfigureColumnValues();
    
    auto LoTime = RA::Timer();
    LoCore.ParseResultsWtihCPU();
    const auto LoSingleThreadData = LoCore.GetDataset(0);
    cout << "Time Single Thread: " << LoTime.GetElapsedTimeMilliseconds() << endl;
    LoTime.Reset();
    LoCore.ParseThreadedResultsWtihCPU(true);
    const auto LoMultiThreadData = LoCore.GetDataset(0);
    cout << "Time Multi  Thread: " << LoTime.GetElapsedTimeMilliseconds() << endl;

    xint LnIdx = 0;
    if (Args.Has('i'))
    {
        LnIdx = Args.Key('i').First().To64();
        cout << "Inspecting: " << LnIdx << endl;
    }
    cout << LoCore.GetDataset(LnIdx) << endl;

    cout << "------------------------" << endl;
    cout << LoSingleThreadData << endl;
    cout << "------------------------" << endl;
    cout << LoMultiThreadData << endl;
    cout << "------------------------" << endl;
    cout << LoCore.GetDataset(LnIdx) << endl;
    cout << "------------------------" << endl;

    FinalRescue();
    Nexus<>::Stop();
    return 0;
}

