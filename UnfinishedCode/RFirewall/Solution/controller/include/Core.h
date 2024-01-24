#pragma once
#pragma warning(disable : 4101)  // for allowing the STL (non-class enum)
#pragma warning(disable : 26812) // for allowing the STL (non-class enum)

#include <iostream>

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QObject>
#include <QQmlApplicationEngine>

#include "Scanner/Dataset.h"
#include "Timer.h"

using std::cout;
using std::endl;

class Core : public QObject {
  Q_OBJECT
public:
  explicit Core(QObject *parent = nullptr);
  virtual ~Core();
  bool Initialize();

  // -------------------------------------------------------------------------
  // QProperties Start
public:
  void SetStopClock(xint unused = 0);

  // QProperties End
  // -------------------------------------------------------------------------
  // C++ Signals Start

signals:
  void sigStartScan(); // Used to reset timer
signals:
  void sigEndScan(); // Used to get time after search execution

  // C++ Signals End
  // -------------------------------------------------------------------------
private:
  QQmlApplicationEngine MoEngine;
  Scanner::Dataset *MoScannerPtr = nullptr;
  RA::Timer MoTimer;
};