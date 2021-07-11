#pragma warning( disable : 4101 )  // for allowing the STL (non-class enum)
#pragma warning( disable : 26812 ) // for allowing the STL (non-class enum)
#pragma warning( disable : 26444 )

#include "Core.h"

#include <QQuickWindow>
#include <QNetworkRequest>
#include <QQmlContext>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "Macros.h"
#include "Enum/Rules.h"
#include "Models/RulesModel.h"

        

Core::Core(QObject* parent) : QObject(parent)
{
    // connect >> this objects function to this lambda
    // so when the statef function is called, the lambda is executed
    connect(this, &Core::sigStartScan, [this]() {
        mTimer.Clear(); // clears out recored lap times
        mTimer.Reset(); // resets the timer to 0
        });

    connect(this, &Core::sigEndScan, [this]() {
        SetStopClock();
        });
}

Core::~Core()
{
    DeleteObject(RulesPtr);
}

bool Core::Initialize()
{
    mEngine.addImportPath("/view/");
    mEngine.addImportPath("/view/Support/");
    mEngine.addImportPath("/view/Constants/");

    // ------------ qmldir Modules--------------------------------------------------------------------------------
    // Adding Requires Modding: (1) Core.cpp (2) qmldir (3) files.qrc
    // Custom QML C++ Types
    qmlRegisterType<RulesModel>("Backend", 1, 0, "RulesModel");
    // Standard QML Objects
    qmlRegisterType(QUrl("qrc:///view/Support/NewRuleForm.qml"),          "Support", 1, 0, "NewRuleForm");
    qmlRegisterType(QUrl("qrc:///view/Support/RulesDelegate.qml"),        "Support", 1, 0, "RulesDelegate");
    qmlRegisterType(QUrl("qrc:///view/Support/RulesView.qml"),            "Support", 1, 0, "RulesView");
    qmlRegisterType(QUrl("qrc:///view/Support/SectionDelegate.qml"),      "Support", 1, 0, "SectionDelegate");

    qmlRegisterType(QUrl("qrc:///view/Mods/MLabel.qml"), "Mods", 1, 0, "MLabel");
    // Singletons
    qmlRegisterSingletonType(QUrl("qrc:///view/Constants/Constants.qml"), "Constants", 1, 0, "Constants");
    // ------------------------------------------------------------------------------------------------------------
    // ------------ C++ Objects 
    mEngine.rootContext()->setContextProperty("Core", this);

    AddQmlClass(Enum::Rules, RulesPtr, "EnumRules");
    // ------------------------------------------------------------------------------------------------------------

    mEngine.load(QUrl(QStringLiteral("qrc:/view/MainWindow.qml"))); // often main.qml

    // below is an example of a default qml value
    //mEngine.rootContext()->setContextProperty("vDisplayTimer", QVariant::fromValue(QString("Exe Time : Never Run")));

    QObject* topLevel = mEngine.rootObjects().value(0);
    QQuickWindow* window = qobject_cast<QQuickWindow*>(topLevel);
    window->show();

    if (mEngine.rootObjects().isEmpty())
        return false;
    else
        return true;
}


// Q_INVOKABLE 
// void Core::ScanFirewallRules()
// {
//     CreateClassObject(Enum::Rules, RulesPtr);
//     // REF(Rules, void());
// }


void Core::SetStopClock(uint unused)
{
    mTimer.Lap(); // recoreds the stopwatch

    // emit self.sigStopClockChanged(mTimer.Get(0)); // I prefer the method below
    mEngine.rootContext()->setContextProperty("vDisplayTimer", QVariant::fromValue(
        QString("Exe Time: ") + QString::number(mTimer.Get(0), 'd', 3)
        //QString("Exe Time: ")+ QString::number(mTimer.Get(0))
    ));
}
