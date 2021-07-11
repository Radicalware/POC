
import QtQuick
import QtQuick.Controls

import Constants
import Mods

ToolBar {
    id: mSectionBreaker
    height: Constants.mTextHeight
    MLabel {
        id: label
        text: section
        anchors.fill: parent
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment:   Qt.AlignVCenter
    }

    background: Image {
        id: mStartBackdrop
        anchors.fill: parent
        source:  "qrc:///resource/backdrops/SectionBar/Section_Off.png"
    }
}
