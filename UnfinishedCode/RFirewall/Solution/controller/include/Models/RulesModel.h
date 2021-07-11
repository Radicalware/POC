
#ifndef Rules_H
#define Rules_H

#include <QAbstractListModel>

#include "Enum/Rule.h"
#include "xvector.h"

namespace Enum // Enumeration
{
    class Rules;
}

#define NewRuleParams \
    const QString& ExeName, \
    const QString& FullPath, \
    const QString& RuleName, \
    const QString& Description, \
    const QString& ServiceName, \
    const QString& LocalAddress, \
    const QString& LocalPort, \
    const QString& RemoteAddress, \
    const QString& RemotePort 


#define SetNewRuleParams() \
    NewRule.ExeName         = WTXS(ExeName.toStdWString().c_str()); \
    NewRule.FullPath        = WTXS(FullPath.toStdWString().c_str()); \
    NewRule.RuleName        = WTXS(RuleName.toStdWString().c_str()); \
    NewRule.Description     = WTXS(Description.toStdWString().c_str()); \
    NewRule.ServiceName     = WTXS(ServiceName.toStdWString().c_str()); \
    NewRule.Local.Address   = WTXS(LocalAddress.toStdWString().c_str()); \
    NewRule.Local.Port      = WTXS(LocalPort.toStdWString().c_str()); \
    NewRule.Remote.Address  = WTXS(RemoteAddress.toStdWString().c_str()); \
    NewRule.Remote.Port     = WTXS(RemotePort.toStdWString().c_str());

class RulesModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum RuleRole {
        ERoleExeName = Qt::DisplayRole,
        ERoleFullPath,
        ERoleRuleName,
        ERoleDescription,
        ERoleServiceName,
        ERoleLocalAddress,
        ERoleLocalPort,
        ERoleRemoteAddress,
        ERoleRemotePort
    };
    Q_ENUM(RuleRole)

    RulesModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex& = QModelIndex()) const;
    QVariant GetData(const QModelIndex& index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    Q_INVOKABLE void PopulateRules(const Enum::Rules* RulesPtr); // MainWindow.mBtnStartSearch.onClicked
    Q_INVOKABLE void Clear();
    Q_INVOKABLE QVariantMap Get(int row) const;
    Q_INVOKABLE void append(const Enum::Rule& NewRule);
    Q_INVOKABLE void append(NewRuleParams);
    Q_INVOKABLE void set(int row, NewRuleParams);
    Q_INVOKABLE void Remove(int row);

private:
    xvector<Enum::Rule> mRules;
};

#endif // Rules_H
