#include <iostream>

#include "Models/RulesModel.h"
#include "Enum/Rule.h"

#include "Macros.h"
#include "Enum/Rule.h"
#include "Enum/Rules.h"

RulesModel::RulesModel(QObject* parent ) : QAbstractListModel(parent)
{
    Enum::Rule NewRule;
    NewRule.ExeName = "Test CppExeName.exe";
    NewRule.FullPath = "Test C:/CppFull/Path/CppExeName.exe";
    NewRule.Description = "Test Cpp Description";
    NewRule.ServiceName = "Test Cpp ServiceName";

    mRules.Add(NewRule);
    //mRules.append({ "Test CppExeName.exe", "Test C:/CppFull/Path/CppExeName.exe", "Test Cpp Description" , "Test Cpp ServiceName" });
}

int RulesModel::rowCount(const QModelIndex&) const
{
    return mRules.size();
}

QVariant RulesModel::GetData(const QModelIndex& index, int role) const
{
    // std::cout << "GetData() << " << mRules.At(index.row()).ExeName.toStdString() << std::endl;
    if (index.row() < rowCount())
        switch (role) {
            case ERoleExeName:      return mRules.At(index.row()).ExeName.c_str();
            case ERoleFullPath:     return mRules.At(index.row()).FullPath.c_str();
            case ERoleRuleName:     return mRules.At(index.row()).RuleName.c_str();
            case ERoleDescription:  return mRules.At(index.row()).Description.c_str();
            case ERoleServiceName:  return mRules.At(index.row()).ServiceName.c_str();
            case ERoleLocalAddress:   return mRules.At(index.row()).Local.Address.c_str();
            case ERoleLocalPort:      return mRules.At(index.row()).Local.Port.c_str();
            case ERoleRemoteAddress:  return mRules.At(index.row()).Remote.Address.c_str();
            case ERoleRemotePort:     return mRules.At(index.row()).Remote.Port.c_str();
        default: return QVariant();
    }
    return QVariant();
}

QHash<int, QByteArray> RulesModel::roleNames() const
{
    static const QHash<int, QByteArray> roles{
        { ERoleExeName,     "exeName" },
        { ERoleFullPath,    "fullPath" },
        { ERoleRuleName,    "ruleName" },
        { ERoleDescription, "description" },
        { ERoleServiceName, "serviceName" },

        { ERoleLocalAddress,    "localAddress" },
        { ERoleLocalPort,       "localPort" },
        { ERoleRemoteAddress,   "remoteAddress" },
        { ERoleRemotePort,      "remotePort" },
    };
    return roles;
}

void RulesModel::PopulateRules(const Enum::Rules* RulesPtr)
{
    REF(Rules, void());
    for (const Enum::Rule& Rule : Rules.GetRules())
    {
        append(Rule);
    }
}

Q_INVOKABLE void RulesModel::Clear()
{
    beginRemoveRows(QModelIndex(), 0, mRules.size()-1);
    mRules.clear();
    endRemoveRows();
    return Q_INVOKABLE void();
}

QVariantMap RulesModel::Get(int row) const
{
    const Enum::Rule rule = mRules.At(row);
    return { 
        {"exeName", rule.ExeName.c_str()},
        {"fullPath", rule.FullPath.c_str()},
        {"description", rule.Description.c_str()},
        {"serviceName", rule.ServiceName.c_str()}
    };
}

Q_INVOKABLE void RulesModel::append(NewRuleParams)
{
    Enum::Rule NewRule;
    SetNewRuleParams();
    append(NewRule);
}

Q_INVOKABLE void RulesModel::append(const Enum::Rule& NewRule)
{
    int row = 0;
    while (row < mRules.size() && NewRule.ExeName.size() > mRules.At(row).ExeName.size())
        ++row;
    beginInsertRows(QModelIndex(), row, row);
    mRules.insert(mRules.begin() + row, NewRule);
    endInsertRows();
}

Q_INVOKABLE void RulesModel::set(int row, NewRuleParams)
{
    if (row < 0 || row >= mRules.size())
        return;

    Enum::Rule NewRule;
    SetNewRuleParams();
    mRules.At(row) = NewRule;
    dataChanged(index(row, 0), index(row, 0), { ERoleExeName, ERoleFullPath, ERoleRuleName, ERoleDescription, ERoleServiceName });
}

Q_INVOKABLE void RulesModel::Remove(int row)
{
    if (row < 0 || row >= mRules.size())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    mRules.erase(mRules.begin() + row);
    endRemoveRows();
}
