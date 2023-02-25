#pragma once

#include "QObject.h"

#include "Macros.h"
#include "Enum/Rule.h"

#include <windows.h>
#include <stdio.h>
#include <comutil.h>
#include <QVariant>
#include <netfw.h>
#include <atlcomcli.h>


#pragma comment( lib, "ole32.lib" )
#pragma comment( lib, "oleaut32.lib" )

namespace Enum // Enumeration Lib set
{
    class Rules : public QObject
    {
        Q_OBJECT;
        const xint LimitSize = 100;
    public:
        Rules();
        ~Rules();
        xvector<Enum::Rule> GetRules() const { return RuleVec;  }
        size_t GetRuleCount() const { return RuleCount;  }
    // -------------------------------------------------------------------------
    // Invokables
public slots:
    Q_INVOKABLE bool ScanRules();
    // -------------------------------------------------------------------------
    // QML Connection Signals Start
private:
    signals: void sigScanRules();
    // -------------------------------------------------------------------------

    private:
        static size_t RuleCount;
        Nexus<Enum::Rule> NexusRules;
        HRESULT WfComInitialize(INetFwPolicy2** ppNetFwPolicy2);
        static Enum::Rule ParseOutRule(INetFwRule* FwRule);
        bool Cleanup(const bool Return = 0);
        void Reset();
        bool bIsClean = true;

        xvector<Enum::Rule> RuleVec;

        HRESULT hrComInit = S_OK;
        HRESULT hr = S_OK;

        ULONG       cFetched = 0;
        CComVariant var;

        IUnknown*       pEnumerator = nullptr;
        IEnumVARIANT*   pVariant = nullptr;

        INetFwPolicy2*  pNetFwPolicy2 = nullptr;
        INetFwRules*    pFwRules = nullptr;
        INetFwRule*     pFwRule = nullptr;
    };
};
