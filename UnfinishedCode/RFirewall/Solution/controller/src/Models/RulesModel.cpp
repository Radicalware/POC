#include "LocalMacros.h"
#include "Models/RulesModel.h"
#include "Enum/Rule.h"

#include "Enum/Rule.h"
#include "Enum/Rules.h"

RulesModel::RulesModel(QObject* parent ) : QAbstractListModel(parent)
{
    Begin();
    Enum::Rule NewRule;
    NewRule.ExeName     = "Test CppExeName.exe";
    NewRule.FullPath    = "Test C:/CppFull/Path/CppExeName.exe";
    NewRule.Description = "Test Cpp Description";
    NewRule.ServiceName = "Test Cpp ServiceName";

    mRules.Add(NewRule);
    //mRules.append({ "Test CppExeName.exe", "Test C:/CppFull/Path/CppExeName.exe", "Test Cpp Description" , "Test Cpp ServiceName" });
    Rescue();
}

int RulesModel::rowCount(const QModelIndex&) const
{
    return mRules.size();
}

QVariant RulesModel::GetData(const QModelIndex& index, int role) const
{
    Begin();
    // std::cout << "GetData() << " << mRules.At(index.row()).ExeName.toStdString() << std::endl;
    if (index.row() < rowCount())
        switch (role) {
            case ERoleExeName:        return mRules.At(index.row()).ExeName.c_str();
            case ERoleFullPath:       return mRules.At(index.row()).FullPath.c_str();
            case ERoleRuleName:       return mRules.At(index.row()).RuleName.c_str();
            case ERoleDescription:    return mRules.At(index.row()).Description.c_str();
            case ERoleServiceName:    return mRules.At(index.row()).ServiceName.c_str();
            case ERoleLocalAddress:   return mRules.At(index.row()).Local.Address.c_str();
            case ERoleLocalPort:      return mRules.At(index.row()).Local.Port.c_str();
            case ERoleRemoteAddress:  return mRules.At(index.row()).Remote.Address.c_str();
            case ERoleRemotePort:     return mRules.At(index.row()).Remote.Port.c_str();
        default: return QVariant();
    }
    return QVariant();
    Rescue();
}

QHash<int, QByteArray> RulesModel::roleNames() const
{
    Begin();
    static const QHash<int, QByteArray> roles{
        { ERoleExeName,         "exeName" },
        { ERoleFullPath,        "fullPath" },
        { ERoleRuleName,        "ruleName" },
        { ERoleDescription,     "description" },
        { ERoleServiceName,     "serviceName" },

        { ERoleLocalAddress,    "localAddress" },
        { ERoleLocalPort,       "localPort" },
        { ERoleRemoteAddress,   "remoteAddress" },
        { ERoleRemotePort,      "remotePort" },
    };
    return roles;
    Rescue();
}

void RulesModel::PopulateRules(const Enum::Rules* RulesPtr)
{
    Begin();
    GET(Rules);
    for (const Enum::Rule& Rule : Rules.GetRules())
    {
        append(Rule);
    }
    Rescue();
}

Q_INVOKABLE void RulesModel::Clear()
{
    Begin();
    beginRemoveRows(QModelIndex(), 0, mRules.size()-1);
    mRules.clear();
    endRemoveRows();
    return Q_INVOKABLE void();
    Rescue();
}

QVariantMap RulesModel::Get(int row) const
{
    Begin();
    const Enum::Rule rule = mRules.At(row);
    return { 
        {"exeName", rule.ExeName.c_str()},
        {"fullPath", rule.FullPath.c_str()},
        {"description", rule.Description.c_str()},
        {"serviceName", rule.ServiceName.c_str()}
    };
    Rescue();
}

Q_INVOKABLE void RulesModel::append(NewRuleParams)
{
    Begin();
    Enum::Rule NewRule;
    SetNewRuleParams();
    append(NewRule);
    Rescue();
}

Q_INVOKABLE void RulesModel::append(const Enum::Rule& NewRule)
{
    Begin();
    int row = 0;
    while (row < mRules.size() && NewRule.ExeName.size() > mRules.At(row).ExeName.size())
        ++row;
    beginInsertRows(QModelIndex(), row, row);
    mRules.insert(mRules.begin() + row, NewRule);
    endInsertRows();
    Rescue();
}

Q_INVOKABLE void RulesModel::set(int row, NewRuleParams)
{
    Begin();
    if (row < 0 || row >= mRules.size())
        return;

    Enum::Rule NewRule;
    SetNewRuleParams();
    mRules.At(row) = NewRule;
    dataChanged(index(row, 0), index(row, 0), { ERoleExeName, ERoleFullPath, ERoleRuleName, ERoleDescription, ERoleServiceName });
    Rescue();
}

Q_INVOKABLE void RulesModel::Remove(int row)
{
    Begin();
    if (row < 0 || row >= mRules.size())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    mRules.erase(mRules.begin() + row);
    endRemoveRows();
    Rescue();
}
