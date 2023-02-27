
#include "Scanner/Rule.h"
#include "re2/re2.h"


const RE2 Scanner::Rule::ExePathPattern(R"(^.*[\\/])");

Scanner::Rule::Rule()
{
}

Scanner::Rule::Rule(const Scanner::Rule& Other)
{
    *this = Other;
}

Scanner::Rule::Rule(Scanner::Rule&& Other) noexcept
{
    *this = std::move(Other);
}

void Scanner::Rule::operator=(const Scanner::Rule& Other)
{
    ExeName = Other.ExeName;
    FullPath = Other.FullPath;
    RuleName = Other.RuleName;
    Description = Other.Description;
    ServiceName = Other.ServiceName;
    IP_Protocol = Other.IP_Protocol;

    Local.Address = Other.Local.Address;
    Local.Port = Other.Local.Port;

    Remote.Address = Other.Remote.Address;
    Remote.Port = Other.Remote.Port;

    ICMP_TypeCode = Other.ICMP_TypeCode;
    Profiles = Other.Profiles;

    Direction = Other.Direction;
    Action = Other.Action;
    Interfaces = Other.Interfaces;
    InterfaceTypes = Other.InterfaceTypes;
    Enabled = Other.Enabled;
    Grouping = Other.Grouping;
    EdgeTraversal = Other.EdgeTraversal;
}

void Scanner::Rule::operator=(Scanner::Rule&& Other)
{
    ExeName = std::move(Other.ExeName);
    FullPath = std::move(Other.FullPath);
    RuleName = std::move(Other.RuleName);
    Description = std::move(Other.Description);
    ServiceName = std::move(Other.ServiceName);
    IP_Protocol = std::move(Other.IP_Protocol);

    Local.Address = std::move(Other.Local.Address);
    Local.Port = std::move(Other.Local.Port);

    Remote.Address = std::move(Other.Remote.Address);
    Remote.Port = std::move(Other.Remote.Port);

    ICMP_TypeCode = std::move(Other.ICMP_TypeCode);
    Profiles = std::move(Other.Profiles);

    Direction = std::move(Other.Direction);
    Action = std::move(Other.Action);
    Interfaces = std::move(Other.Interfaces);
    InterfaceTypes = std::move(Other.InterfaceTypes);
    Enabled = std::move(Other.Enabled);
    Grouping = std::move(Other.Grouping);
    EdgeTraversal = std::move(Other.EdgeTraversal);
}
