#include <QGuiApplication>
#include <QQuickStyle>

#define _uint_

#include "Nexus.h"
#include "Core.h"



int main(int argc, char *argv[])
{
    int LnReValue = 0;
    Begin();
    Nexus<>::Start();
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QQuickStyle::setStyle("Fusion");

    QGuiApplication LoApp(argc, argv);
    Core LoCore;

    if (LoCore.Initialize())
        LnReValue = LoApp.exec();
    else
        LnReValue = -1;

    RescuePrint();
    LnReValue = Nexus<>::Stop();
    return LnReValue;
}
