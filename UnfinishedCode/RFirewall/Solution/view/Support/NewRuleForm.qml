
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Constants

GridLayout {
    id: mTop

    // alies needed by 
    property alias exeName:         exeName
    property alias fullPath:        fullPath
    property alias description:     description
    property alias serviceName:     serviceName

    property alias localAddress:    localAddress
    property alias localPort:       localPort
    property alias remoteAddress:   remoteAddress
    property alias remotePort:      remotePort

    property int minimumInputSize: 120
    property string placeholderText: qsTr("<enter>")

    rows: 4
    columns: 2

    // ------------------------------------------------------------
    Label {
        text: qsTr("Exe Name")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: exeName
        focus: true
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Full Path")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: fullPath
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------

    Label {
        text: qsTr("Rule Name")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: ruleName
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Description")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: description
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Service Name")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: serviceName
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Local Address")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: localAddress
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Local Port")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: localPort
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Remote Address")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: remoteAddress
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
    Label {
        text: qsTr("Remote Port")
        color: Constants.mTextColor
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }
    TextField {
        id: remotePort
        Layout.fillWidth: true
        Layout.minimumWidth: mTop.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: mTop.placeholderText
    }
    // ------------------------------------------------------------
}
