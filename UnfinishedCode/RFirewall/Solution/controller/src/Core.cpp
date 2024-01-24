#pragma warning(disable : 4101) // for allowing the STL (non-class enum)
#pragma warning(disable : 26812) // for allowing the STL (non-class enum)
#pragma warning(disable : 26444)

#include "Core.h"
#include "LocalMacros.h"

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QQmlContext>
#include <QQuickWindow>

#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "Models/RulesModel.h"

Core::Core(QObject *parent) : QObject(parent) {
  Begin();
  // connect >> this objects function to this lambda
  // so when the statef function is called, the lambda is executed
  connect(this, &Core::sigStartScan, [this]() {
    MoTimer.Clear(); // clears out recored lap times
    MoTimer.Reset(); // resets the timer to 0
  });

  connect(this, &Core::sigEndScan, [this]() { SetStopClock(); });
  Rescue();
}

Core::~Core() { HostDelete(MoScannerPtr); }

bool Core::Initialize() {
  Begin();
  MoEngine.addImportPath("/view/");
  MoEngine.addImportPath("/view/Backend/");
  MoEngine.addImportPath("/view/Constants/");
  MoEngine.addImportPath("/view/Mods/");
  MoEngine.addImportPath("/view/Support/");

  // ------------ qmldir Modules
  // ------------------------------------------------------------------------------------------
  // Adding Requires Modding: (1) Core.cpp (2) qmldir (3) files.qrc

  // Backend Models
  qmlRegisterType<Scanner::RulesModel>("Backend", 1, 0, "RulesModel");
  // Support
  qmlRegisterType(QUrl("qrc:///view/Support/NewRuleForm.qml"), "Support", 1, 0,
                  "NewRuleForm");
  qmlRegisterType(QUrl("qrc:///view/Support/RulesDelegate.qml"), "Support", 1,
                  0, "RulesDelegate");
  qmlRegisterType(QUrl("qrc:///view/Support/RulesView.qml"), "Support", 1, 0,
                  "RulesView");
  qmlRegisterType(QUrl("qrc:///view/Support/SectionDelegate.qml"), "Support", 1,
                  0, "SectionDelegate");
  // Mods
  qmlRegisterType(QUrl("qrc:///view/Mods/MLabel.qml"), "Mods", 1, 0, "MLabel");
  // Singletons
  qmlRegisterSingletonType(QUrl("qrc:///view/Constants/Constants.qml"),
                           "Constants", 1, 0, "Constants");
  // ----------------------------------------------------------------------------------------------------------------------
  // ------------ C++ Objects

  AddQmlClass(Scanner::Dataset, MoScanner,
              "MoScanner"); // Type, Local Var, QML Var

  MoEngine.rootContext()->setContextProperty("Core", this);

  // ------------------------------------------------------------------------------------------------------------

  MoEngine.load(QUrl("qrc:///view/MainWindow.qml")); // often main.qml

  // below is an example of a default qml value
  // MoEngine.rootContext()->setContextProperty("vDisplayTimer",
  // QVariant::fromValue(QString("Exe Time : Never Run")));

  QObject *topLevel = MoEngine.rootObjects().value(0);
  QQuickWindow *window = qobject_cast<QQuickWindow *>(topLevel);
  window->show();

  if (MoEngine.rootObjects().isEmpty())
    return false;
  else
    return true;
  Rescue();
}

void Core::SetStopClock(xint unused) {
  Begin();
  MoTimer.Lap(); // recoreds the stopwatch

  // emit self.sigStopClockChanged(mTimer.Get(0)); // I prefer the method below
  MoEngine.rootContext()->setContextProperty(
      "vDisplayTimer",
      QVariant::fromValue(
          QString("Exe Time: ") + QString::number(MoTimer.Get(0), 'd', 3)
          // QString("Exe Time: ")+ QString::number(mTimer.Get(0))
          ));
  Rescue();
}