#pragma once

#include "xstring.h"
#include "re2/re2.h"

// All of these are strings because all getters
// from INetFwRule are return as strings;

namespace Scanner
{
    struct Rule
    {
        Rule();
        Rule(const Scanner::Rule & Other);
        Rule(Scanner::Rule && Other) noexcept;

        void operator=(const Scanner::Rule& Other);
        void operator=(Scanner::Rule&& Other);
        bool operator==(const Scanner::Rule& Other) const { return RuleName == Other.RuleName;  }

        static const RE2 ExePathPattern;

        xstring ExeName;
        xstring FullPath;
        xstring RuleName;
        xstring Description;
        xstring ServiceName;
        xstring IP_Protocol;

        struct Net_Address
        {
            xstring Address;
            xstring Port;
        };
        Net_Address Local;
        Net_Address Remote;
        xstring ICMP_TypeCode;

        //struct Profile
        //{
        //    bool Domain  = false;
        //    bool Private = false;
        //    bool Public  = false;
        //};
        //Profile Profile;

        xvector<xstring> Profiles;

        xstring Direction;
        xstring Action;
        xvector<xstring> Interfaces;
        xstring InterfaceTypes;
        xstring Enabled;
        xstring Grouping;
        xstring EdgeTraversal;
    };
};

// -------- EXAMPLE ---------------------------------------------------------------------------------------------------
// Name:             [TWXN8IMUaFQyye] TCP Listen Ports
// Description:
// Application Name: C:\Program Files\WindowsApps\Microsoft.YourPhone_1.20012.135.0_x64__8wekyb3d8bbwe\YourPhone.exe
// Service Name:     (null)
// IP Protocol:      TCP
// LocalAddresses:   *
// Local Ports:      *
// RemoteAddresses:  *
// Remote Ports:     *
// Profile:  Domain
// Profile:  Private
// Profile:  Public
// Direction:        In
// Action:           Allow
// Interface Types:  All
// Enabled:          TRUE
// Grouping:         (null)
// Edge Traversal:   FALSE

