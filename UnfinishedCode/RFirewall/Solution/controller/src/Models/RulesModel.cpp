#include "LocalMacros.h"
#include "Models/RulesModel.h"

#include "Scanner/Rule.h"
#include "Scanner/Dataset.h"

Scanner::RulesModel::RulesModel(QObject* parent ) : QAbstractListModel(parent)
{
    Begin();
    //Scanner::Rule NewRule;
    //NewRule.ExeName     = "Test CppExeName.exe";
    //NewRule.FullPath    = "Test C:/CppFull/Path/CppExeName.exe";
    //NewRule.Description = "Test Cpp Description";
    //NewRule.ServiceName = "Test Cpp ServiceName";

    //mRules.Add(NewRule);
    //mRules.append({ "Test CppExeName.exe", "Test C:/CppFull/Path/CppExeName.exe", "Test Cpp Description" , "Test Cpp ServiceName" });
    Rescue();
}

int Scanner::RulesModel::rowCount(const QModelIndex&) const
{
    return mRules.size();
}

QVariant Scanner::RulesModel::GetData(const QModelIndex& index, int role) const
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

QHash<int, QByteArray> Scanner::RulesModel::roleNames() const
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

void Scanner::RulesModel::PopulateRules(const Scanner::Dataset* RulesPtr)
{
    Begin();
    GET(Rules);
    Rules.GetRules().Proc([this](const auto& LoRule) { The.append(LoRule);  return false; });
    Rescue();
}

Q_INVOKABLE void Scanner::RulesModel::Clear()
{
    Begin();
    if (!mRules)
        return;
    beginRemoveRows(QModelIndex(), 0, mRules.size()-1);
    mRules.clear();
    endRemoveRows();
    Rescue();
}

QVariantMap Scanner::RulesModel::Get(int row) const
{
    Begin();
    const Scanner::Rule rule = mRules.At(row);
    return { 
        {"exeName", rule.ExeName.c_str()},
        {"fullPath", rule.FullPath.c_str()},
        {"description", rule.Description.c_str()},
        {"serviceName", rule.ServiceName.c_str()}
    };
    Rescue();
}

Q_INVOKABLE void Scanner::RulesModel::append(NewRuleParams)
{
    Begin();
    Scanner::Rule NewRule;
    SetNewRuleParams();
    append(NewRule);
    Rescue();
}

Q_INVOKABLE void Scanner::RulesModel::append(const Scanner::Rule& NewRule)
{
    Begin();
    int row = 0;
    while (row < mRules.size() && NewRule.ExeName > mRules.At(row).ExeName)
        ++row;
    beginInsertRows(QModelIndex(), row, row);
    mRules.insert(mRules.begin() + row, NewRule);
    endInsertRows();
    Rescue();
}

Q_INVOKABLE void Scanner::RulesModel::set(int row, NewRuleParams)
{
    Begin();
    if (row < 0 || row >= mRules.size())
        return;

    Scanner::Rule NewRule;
    SetNewRuleParams();
    mRules.At(row) = NewRule;
    dataChanged(index(row, 0), index(row, 0), { ERoleExeName, ERoleFullPath, ERoleRuleName, ERoleDescription, ERoleServiceName });
    Rescue();
}

Q_INVOKABLE void Scanner::RulesModel::Remove(int row)
{
    Begin();
    if (row < 0 || row >= mRules.size())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    mRules.erase(mRules.begin() + row);
    endRemoveRows();
    Rescue();
}
