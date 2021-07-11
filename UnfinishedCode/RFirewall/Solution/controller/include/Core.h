#pragma once
#pragma warning( disable : 4101 )  // for allowing the STL (non-class enum)
#pragma warning( disable : 26812 ) // for allowing the STL (non-class enum)

#include <iostream>

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlApplicationEngine>

#include "Timer.h"

using std::cout;
using std::endl;

namespace Enum // Enumeration Lib set
{
    class Rules;
};

class Core : public QObject
{
    Q_OBJECT
public:
    explicit Core(QObject* parent = nullptr);
    virtual ~Core();
    bool Initialize();

    // -------------------------------------------------------------------------
    // Invokables

// public slots:
//     Q_INVOKABLE void ScanFirewallRules();

    // Invokables
    // -------------------------------------------------------------------------
    // QProperties Start 
public:
    void SetStopClock(uint unused = 0);

    // QProperties End
    // -------------------------------------------------------------------------
    // C++ Signals Start

    signals: void sigStartScan(); // Used to reset timer
    signals: void sigEndScan();   // Used to get time after search execution

    // C++ Signals End
    // -------------------------------------------------------------------------
private:
    QQmlApplicationEngine mEngine;
    Enum::Rules* RulesPtr = nullptr;
    Timer mTimer;
};

