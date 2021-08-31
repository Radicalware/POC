#include <QGuiApplication>

#include "Nexus.h"
#include "Core.h"



int main(int argc, char *argv[])
{
    Nexus<>::Start();
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    Core core;
    int retValue = 0;

    if (core.Initialize())
        retValue = app.exec();
    else
        retValue = -1;

    Nexus<>::Stop();
    return retValue;
}
