
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Constants
import Mods

// ItemDelegate: sets the list-view's item properties
// ListView.model = ItemDelegate

ItemDelegate {
    id: mTop
    checkable: true

    // property alias mTop: mReference // failes in ItemDelegate type

    contentItem: ColumnLayout {
        spacing: 10

        MLabel {
            color: index % 2 == 0 ? Constants.mTextColor : Constants.mTextColor
            text: exeName
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        GridLayout {
            id: grid
            visible: false

            columns: 2
            rowSpacing: 10
            columnSpacing: 10
            
            // ------------------------------------------
            MLabel {
                text: qsTr("Full Path:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: fullPath
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Rule Name:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: ruleName
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Description:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: description
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Service Name:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: serviceName
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Local Address:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: localAddress
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Local Port:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: localPort
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Remote Address:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: remoteAddress
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            // ------------------------------------------
            MLabel {
                text: qsTr("Remote Port:")
                Layout.leftMargin: 60
            }
            MLabel {
                text: remotePort
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
    
    background: Rectangle {
        anchors.fill: parent
        color: "#0100d4"
        opacity: 0.5
    }

    states: [
        State {
            name: "expanded"
            when: mTop.checked

            PropertyChanges {
                target: grid
                visible: true
            }
        }
    ]
}
