
#ifndef Rules_H
#define Rules_H

#include <QAbstractListModel>

#include "Scanner/Rule.h"
#include "xvector.h"

namespace Scanner
{
    class Dataset;
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
    NewRule.ExeName         = ExeName.toStdWString(); \
    NewRule.FullPath        = FullPath.toStdWString(); \
    NewRule.RuleName        = RuleName.toStdWString(); \
    NewRule.Description     = Description.toStdWString(); \
    NewRule.ServiceName     = ServiceName.toStdWString(); \
    NewRule.Local.Address   = LocalAddress.toStdWString(); \
    NewRule.Local.Port      = LocalPort.toStdWString(); \
    NewRule.Remote.Address  = RemoteAddress.toStdWString(); \
    NewRule.Remote.Port     = RemotePort.toStdWString();

namespace Scanner
{
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
        QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const { return GetData(index, role); }
        QHash<int, QByteArray> roleNames() const;

        // MainWindow.mBtnStartSearch.onClicked
        Q_INVOKABLE void PopulateRules(const Scanner::Dataset* RulesPtr);
        Q_INVOKABLE void Clear();
        Q_INVOKABLE QVariantMap Get(int row) const;
        Q_INVOKABLE void append(const Scanner::Rule& NewRule);
        Q_INVOKABLE void append(NewRuleParams);
        Q_INVOKABLE void set(int row, NewRuleParams);
        Q_INVOKABLE void Remove(int row);

    private:
        xvector<Scanner::Rule> mRules;
    };
};
#endif // Rules_H
