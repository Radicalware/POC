
/*
* Copyright[2019][Joel Leagues aka Scourge]
* Scourge /at\ protonmail /dot\ com
* www.Radicalware.com
* https://www.youtube.com/channel/UCivwmYxoOdDT3GmDnD0CfQA/playlists
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http ://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

// DEBUG ARGS: -r rxm::icase -d C:\source\Tools\afs -o

#include "Timer.h"
#include "SYS.h"
#include "xstring.h"

#include "Core.h"
#include "Options.h"

// #include <vld.h>


int Help(int FnReturnError) {
    cout << R"(

    Scan is used to scan for text in files Recursivly.

    ------------------------------------------------------------------
      REQUIRED
    ------------------------------------------------------------------
      -r     |  --regex     |  (str)   Regex To Search For
    ------------------------------------------------------------------
      USUAL ARGUMENTS
    ------------------------------------------------------------------
      -d     |  --dir       |  (str)   Directory To Search In
      -t     |  --threads   |  (int)   Set Thread Count
      -v     |  --void      |  (array) Void search these syntax
      -a     |  --avoid     |  (array) Avoid searching these paths
      -t     |  --target    |  (array) Target searching these paths
      -f     |  --full      |  (bool)  Show the Full Path
      -c     |  --case      |  (bool)  Case-Sensitive Regex
      -b     |  --binary    |  (bool)  Search Binary Files 
      -n     |  --name      |  (bool)  Only Name the Files Found
      -l     |  --errors    |  (bool)  Include locked file errors
    ------------------------------------------------------------------
       THESE CHANGE THE STANDARD PROCEDURE
    ------------------------------------------------------------------
      -o     |  --one       |  (bool)  Run Only Under 'One' Thread
    ------------------------------------------------------------------
      -m     |  --modify    |  (bool)  Open the File to 'Modify' It
    ------------------------------------------------------------------
      -p     |  --pipe      |  (bool)  Consume Piped Data
      -e     |  --entire    |  (bool)  Show the entire 
    ------------------------------------------------------------------

    If no '-' are found in args are parsed as argv[x][0] 
    then the following parsed method will be uesd. 

    if (argc == 2) // requires stdin
        argv[1] =  "regex"

    if (argc == 3)
        argv[1] = "directory to search in"
        argv[2] = "regex"

    if (argc > 3)
        Use the KVPs as described in the table above.

)";
    return Nexus<>::Stop();
}



int main(int argc, char** argv) 
{   
    Begin();
    Nexus<>::Start();

    RA::Timer LoTimer;
    RA::SYS LoSys;
    Options LoOption;
    Core core(LoOption);

    LoSys.AddAlias('r', "--regex");  // -- always required

    LoSys.AddAlias('d', "--dir");    // -- usual bools
    LoSys.AddAlias('t', "--threads");
    LoSys.AddAlias('v', "--void");   // -- while discarding matches with this regex
    LoSys.AddAlias('a', "--avoid");  // -- avoiding the files and directories
    LoSys.AddAlias('t', "--target"); // -- target the files and directories
    LoSys.AddAlias('f', "--full");
    LoSys.AddAlias('c', "--case");
    LoSys.AddAlias('b', "--binary");
    LoSys.AddAlias('n', "--name");
    LoSys.AddAlias('l', "--locked");

    LoSys.AddAlias('o', "--one");    // -- setting only one thread path is not the same as -t 1
    LoSys.AddAlias('m', "--modify");

    LoSys.AddAlias('p', "--pipe");   // -- piped path
    LoSys.AddAlias('e', "--entire");

    LoSys.SetArgs(argc, argv);

    if (LoSys.Help()) 
        return Help(0);

    auto FindRexArg = [&core, &LoSys, &LoOption]() -> void 
    { // note: argv[0] is the program path
        if (LoSys.ArgC() == 2 && !LoSys('r')) // no --regex && 1 prog args == set argv[1] as the regex
            LoOption.SetRegex(LoSys[1]);
        else if (LoSys.ArgC() > 2 && !LoSys('r'))  // no --regex && over 1 prog arg == set argv[2] as the regex
            LoOption.SetRegex(LoSys[2]);
        else
            LoOption.SetRegex(LoSys['r'][0]);
    };

    if (!LoSys('d')) LoOption.SetDirectory(RA::OS::PWD(), true);
    else             LoOption.SetDirectory(LoSys['d'][0]);

    if (LoSys('t')) RA::Threads::SetAllowedThreadCount((LoSys['t'][0]).ToInt());
    if (LoSys('f')) LoOption.MbUseFullPath = true;
    if (LoSys('c')) LoOption.MoRex.MbCaseSensitive = true;
    if (LoSys('b')) LoOption.MbBinaraySearchOn = true;
    if (LoSys('n')) LoOption.MbOnlyNameFiles = true;
    if (LoSys('m')) LoOption.MbModify = true;
    if (LoSys('l')) LoOption.MoIncludeLockedFileErros = true;

    if (LoSys('p')) LoOption.MbPiped = true;
    if (LoSys('e')) LoOption.MbEntire = true;

    // use piped scan if there is ony one arg and it is not a key
    if ((LoSys.ArgC() == 2 && LoSys [1][0] != '-') || LoOption.MbPiped)
    {
        FindRexArg();
        core.PipedScan();
        core.Print();
        return Nexus<>::Stop(); // << -------- return ----------------------
    }
    else if (!LoSys.HasArgs()) {
        if (argc == 2) {
            LoOption.SetRegex(argv[1]);
            LoOption.SetDirectory(RA::OS::PWD(), true);
        }
        else if (argc == 3) {
            LoOption.SetDirectory(argv[1]);
            LoOption.SetRegex(argv[2]);
        }
        else {
            return Help(1); // << -------- return -----------
        }
    }
    else 
    {
        FindRexArg();
    }
    if (LoSys('v'))  LoOption.SetAvoidRegex(LoSys['v']);
    if (LoSys('a'))  LoOption.SetAvoidDirectories(LoSys['a']);
    if (LoSys('t'))  LoOption.SetTargetDirectories(LoSys['t']);

    core.PrintDivider();
    if (LoSys('o')) {
        core.SingleCoreScan();
        core.Print();
        cout << Color::Cyan << "Single-Threaded\n" << Color::Mod::Reset;
    }
    else {
        core.MultiCoreScan();
        core.Print();
        cout << Color::Cyan << "Threads Availible: " << RA::Threads::GetThreadCountAvailable() << Color::Mod::Reset << endl;
    }
    cout << Color::Cyan << "Time: " << LoTimer << Color::Mod::Reset << endl;
    core.PrintDivider();

    FinalRescue();
    return Nexus<>::Stop();
}

