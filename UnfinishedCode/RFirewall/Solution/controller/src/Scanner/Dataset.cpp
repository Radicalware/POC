#include "LocalMacros.h"
#include "Scanner/Dataset.h"

#include "QString.h"

#include <sstream>
#include <iostream>


// Much of the code you see below has been programed by Microsoft
/************************************************************************
Copyright (C) Microsoft. All Rights Reserved.

Abstract:
    This C++ file includes sample code for enumerating Windows Firewall
    rules using the Microsoft Windows Firewall APIs.
*************************************************************************/

#define NET_FW_IP_PROTOCOL_TCP_NAME L"TCP"
#define NET_FW_IP_PROTOCOL_UDP_NAME L"UDP"

#define NET_FW_RULE_DIR_IN_NAME  L"In"
#define NET_FW_RULE_DIR_OUT_NAME L"Out"

#define NET_FW_RULE_ACTION_ALLOW_NAME L"Allow"
#define NET_FW_RULE_ACTION_BLOCK_NAME L"Block"

#define NET_FW_RULE_ENABLE_IN_NAME  L"TRUE"
#define NET_FW_RULE_DISABLE_IN_NAME L"FALSE"

const xstring StrTCP   = "TCP";
const xstring StrUDP   = "UDP";

const xstring StrIn    = "In";
const xstring StrOut   = "Out";

const xstring StrAllow = "Allow";
const xstring StrBlock = "Block";

const xstring StrTrue  = "True";
const xstring StrFalse = "False";

const xstring StrEnabled   = "True";
const xstring StrDisabled  = "False";

using std::cout;
using std::endl;

size_t Scanner::Dataset::RuleCount = 0;

Scanner::Dataset::Dataset()
{
    Begin();
    ScanRules();
    Rescue();
}

Scanner::Dataset::~Dataset()
{
    Cleanup(0);
}

Q_INVOKABLE
bool Scanner::Dataset::ScanRules()
{
    Begin();
    Reset();
    long fwRuleCount;

    // Initialize COM.
    hrComInit = CoInitializeEx(
        0,
        COINIT_APARTMENTTHREADED
    );

    // Ignore RPC_E_CHANGED_MODE; this just means that COM has already been
    // initialized with a different mode. Since we don't care what the mode is,
    // we'll just use the existing mode.
    if (hrComInit != RPC_E_CHANGED_MODE)
    {
        if (FAILED(hrComInit))
        {
            wprintf(L"CoInitializeEx failed: 0x%08lx\n", hrComInit);

            if (SUCCEEDED(hrComInit))
                CoUninitialize();

            return false;
        }
    }

    // Retrieve INetFwPolicy2
    hr = WfComInitialize(&pNetFwPolicy2);

    if (FAILED(hr))
    {
        if (pNetFwPolicy2)
            pNetFwPolicy2->Release();

        if (SUCCEEDED(hrComInit))
            CoUninitialize();

        return false;
    }

    // Retrieve INetFwRules
    hr = pNetFwPolicy2->get_Rules(&pFwRules);
    if (FAILED(hr))
    {
        wprintf(L"get_Rules failed: 0x%08lx\n", hr);
        return Cleanup(false);
    }

    // Obtain the number of Firewall rules
    hr = pFwRules->get_Count(&fwRuleCount);
    if (FAILED(hr))
    {
        wprintf(L"get_Count failed: 0x%08lx\n", hr); 
        return Cleanup(false);
    }

    RuleCount = static_cast<size_t>(fwRuleCount);

    // Iterate through all of the rules in pFwRules
    pFwRules->get__NewEnum(&pEnumerator);

    if (pEnumerator)
        hr = pEnumerator->QueryInterface(__uuidof(IEnumVARIANT), (void**)&pVariant);

    xint Looper = LimitSize;

    while (SUCCEEDED(hr) && hr != S_FALSE)
    {
        var.Clear();
        hr = pVariant->Next(1, &var, &cFetched);

        if (S_FALSE != hr)
        {
            if (SUCCEEDED(hr)) hr = var.ChangeType(VT_DISPATCH);
            if (SUCCEEDED(hr)) hr = (V_DISPATCH(&var))->QueryInterface(__uuidof(INetFwRule), reinterpret_cast<void**>(&pFwRule));
            if (SUCCEEDED(hr) && pFwRule) {
                if(pFwRule)
                    NexusRules.AddTask(&Scanner::Dataset::ParseOutRule, pFwRule); // Output the properties of this rule
            }
        }

        if (LimitSize)
        {
            Looper--;
            if (!Looper)
                break;
        }
    }
    RuleVec.erase(RuleVec.begin(), RuleVec.end());
    NexusRules.WaitAll();
    RuleVec.reserve(NexusRules.Size()+1);

    auto LvRules = NexusRules.GetMoveAllIndices();

    // Add values with name
    for (auto& LoRulePtr : LvRules)
    {
        GET(LoRule);
        if (!LoRule.ExeName)
            LoRule.ExeName = "{NameLess}";
        if (!RuleVec.Has(LoRule))
            RuleVec.Add(LoRulePtr);
    }

    RuleVec.Sort([](const auto& One, const auto& Two) { return One.ExeName > Two.ExeName; });

    return Cleanup(true); // success
    Rescue();
}

HRESULT Scanner::Dataset::WfComInitialize(INetFwPolicy2** ppNetFwPolicy2)
{
    Begin();
    HRESULT hr = S_OK;

    hr = CoCreateInstance(
        __uuidof(NetFwPolicy2),
        NULL,
        CLSCTX_INPROC_SERVER,
        __uuidof(INetFwPolicy2),
        (void**)ppNetFwPolicy2);

    if (FAILED(hr))
        wprintf(L"CoCreateInstance for INetFwPolicy2 failed: 0x%08lx\n", hr);

    return hr;
    Rescue();
}

xp<Scanner::Rule> Scanner::Dataset::ParseOutRule(INetFwRule* FwRule)
{
    Begin();
    NEW(LoRule, MKP<Scanner::Rule>());

    variant_t InterfaceArray;
    variant_t InterfaceString;

    VARIANT_BOOL bEnabled;
    BSTR bstrVal;

    long lVal = 0;
    long lProfileBitmask = 0;

    NET_FW_RULE_DIRECTION fwDirection;
    NET_FW_ACTION fwAction;

    struct ProfileMapElement
    {
        NET_FW_PROFILE_TYPE2 Id;
        LPCWSTR Name;
    };

    ProfileMapElement ProfileMap[3];
    ProfileMap[0].Id = NET_FW_PROFILE2_DOMAIN;
    ProfileMap[0].Name = L"Domain";
    ProfileMap[1].Id = NET_FW_PROFILE2_PRIVATE;
    ProfileMap[1].Name = L"Private";
    ProfileMap[2].Id = NET_FW_PROFILE2_PUBLIC;
    ProfileMap[2].Name = L"Public";

    if (SUCCEEDED(FwRule->get_Name(&bstrVal)))
        LoRule.RuleName = bstrVal;

    if (SUCCEEDED(FwRule->get_Description(&bstrVal)))
        LoRule.Description = bstrVal;

    if (SUCCEEDED(FwRule->get_ApplicationName(&bstrVal))) {
        LoRule.FullPath = bstrVal;
        LoRule.ExeName = LoRule.FullPath.Sub(Scanner::Rule::ExePathPattern, xstring::StaticClass);
    }

    if (SUCCEEDED(FwRule->get_ServiceName(&bstrVal)))
        LoRule.ServiceName = bstrVal;

    if (SUCCEEDED(FwRule->get_Protocol(&lVal)))
    {
        switch (lVal)
        {
        case NET_FW_IP_PROTOCOL_TCP:
            LoRule.IP_Protocol = StrTCP;
            break;
        case NET_FW_IP_PROTOCOL_UDP:
            LoRule.IP_Protocol = StrUDP;
            break;
        default:
            break;
        }

        if (lVal != NET_FW_IP_VERSION_V4 && lVal != NET_FW_IP_VERSION_V6)
        {
            if (SUCCEEDED(FwRule->get_LocalPorts(&bstrVal)))
                LoRule.Local.Port = bstrVal;

            if (SUCCEEDED(FwRule->get_RemotePorts(&bstrVal)))
                LoRule.Remote.Port = bstrVal;
        }
        else if (SUCCEEDED(FwRule->get_IcmpTypesAndCodes(&bstrVal)))
            LoRule.ICMP_TypeCode = bstrVal;
    }

    if (SUCCEEDED(FwRule->get_LocalAddresses(&bstrVal)))
        LoRule.Local.Address = bstrVal;

    if (SUCCEEDED(FwRule->get_RemoteAddresses(&bstrVal)))
        LoRule.Remote.Address = bstrVal;

    if (SUCCEEDED(FwRule->get_Profiles(&lProfileBitmask)))
    {
        // The returned bitmask can have more than 1 bit set if multiple profiles 
        //   are active or current at the same time

        for (int i = 0; i < 3; i++)
        {
            if (lProfileBitmask & ProfileMap[i].Id)
                LoRule.Profiles.Add(ProfileMap[i].Name);
            // todo: check the profile map and set bools for their types
        }
    }

    if (SUCCEEDED(FwRule->get_Direction(&fwDirection)))
    {
        switch (fwDirection)
        {
        case NET_FW_RULE_DIR_IN:

            LoRule.Direction = StrIn;
            break;

        case NET_FW_RULE_DIR_OUT:
            LoRule.Direction = StrOut;
            break;
        default:
            break;
        }
    }

    if (SUCCEEDED(FwRule->get_Action(&fwAction)))
    {
        switch (fwAction)
        {
        case NET_FW_ACTION_BLOCK:
            LoRule.Action = StrBlock;
            break;

        case NET_FW_ACTION_ALLOW:
            LoRule.Action = StrAllow;
            break;
        default:
            break;
        }
    }

    if (SUCCEEDED(FwRule->get_Interfaces(&InterfaceArray)))
    {
        if (InterfaceArray.vt != VT_EMPTY)
        {
            SAFEARRAY* pSa = NULL;
            pSa = InterfaceArray.parray;
            for (long index = pSa->rgsabound->lLbound; index < (long)pSa->rgsabound->cElements; index++)
            {
                SafeArrayGetElement(pSa, &index, &InterfaceString);
                LoRule.Interfaces.Add(InterfaceString.bstrVal);
            }
        }
    }

    if (SUCCEEDED(FwRule->get_InterfaceTypes(&bstrVal)))
        LoRule.InterfaceTypes = bstrVal;

    if (SUCCEEDED(FwRule->get_Enabled(&bEnabled)))
    {
        if (bEnabled)
            LoRule.Enabled = StrEnabled;
        else
            LoRule.Enabled = StrDisabled;
    }

    if (SUCCEEDED(FwRule->get_Grouping(&bstrVal)))
        LoRule.Grouping = bstrVal;

    if (SUCCEEDED(FwRule->get_EdgeTraversal(&bEnabled)))
    {
        if (bEnabled)
            LoRule.EdgeTraversal = StrEnabled;
        else
            LoRule.EdgeTraversal = StrDisabled;
    }
    return LoRulePtr;
    Rescue();
}

bool Scanner::Dataset::Cleanup(const bool Return)
{
    Begin();
    if (bIsClean)
        return Return;

    if (pFwRule != nullptr)
        pFwRule->Release();

    // Release INetFwPolicy2
    if (pNetFwPolicy2 != nullptr)
        pNetFwPolicy2->Release();

    // Uninitialize COM.
    if (SUCCEEDED(hrComInit))
        CoUninitialize();

    bIsClean = true;
    return Return;
    Rescue();
}

void Scanner::Dataset::Reset()
{
    Begin();
    NexusRules.Clear();

    if (!bIsClean)
        Cleanup();

    hrComInit = S_OK;
    hr = S_OK;

    cFetched = 0;
    var.Clear();

    pEnumerator = nullptr;
    pVariant = nullptr;

    pNetFwPolicy2 = nullptr;
    pFwRules = nullptr;
    pFwRule = nullptr;
    Rescue();
}
