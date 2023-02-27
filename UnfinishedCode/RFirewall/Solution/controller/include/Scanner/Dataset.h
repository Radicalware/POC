#pragma once

#include "QObject.h"

#include "Macros.h"
#include "Scanner/Rule.h"

#include <windows.h>
#include <stdio.h>
#include <comutil.h>
#include <QVariant>
#include <netfw.h>
#include <atlcomcli.h>


#pragma comment( lib, "ole32.lib" )
#pragma comment( lib, "oleaut32.lib" )

namespace Scanner
{
    class Dataset : public QObject
    {
        Q_OBJECT;
        const xint LimitSize = 100;
    public:
        Dataset();
        ~Dataset();
        xvector<xp<Scanner::Rule>> GetRules() const { return RuleVec;  }
        size_t GetRuleCount() const { return RuleCount;  }
    // -------------------------------------------------------------------------
    // Invokables
public slots:
    Q_INVOKABLE bool ScanRules();
    // -------------------------------------------------------------------------
    // QML Connection Signals Start
    signals: void sigScanRules();
    // -------------------------------------------------------------------------

    private:
        HRESULT WfComInitialize(INetFwPolicy2** ppNetFwPolicy2);
        static xp<Scanner::Rule> ParseOutRule(INetFwRule* FwRule);

        bool Cleanup(const bool Return = 0);
        void Reset();
        bool bIsClean = true;

        static size_t RuleCount;
        Nexus<xp<Scanner::Rule>> NexusRules;

        xvector<xp<Scanner::Rule>> RuleVec;

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
