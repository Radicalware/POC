
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects


import Support
import Constants

ApplicationWindow {
    id: window

    // width: 600
    // height: 1000
    // Constants.mWidth: width
    // Constants.mHeight: height

    width:  Constants.mWidth
    height: Constants.mHeight

    property int mSelectedRule: -1

    visible: true
    title: qsTr("Contact List")

    ManageRuleDialog {
        id: mManageRuleDialog
        onFinished: {
            if (mSelectedRule === -1)
               mRuleView.model.append(exeName, fullPath, description, serviceName, 
                                        localAddress, localPort, remoteAddress, remotePort)
            else
               mRuleView.model.set(exeName,  fullPath, description, serviceName,
                                        localAddress, localPort, remoteAddress, remotePort)
        }
    }

    // Menu objects >> Instantiated when mContactMenu.Open() is called
    Menu {
        id: mContactMenu
        anchors.centerIn: parent
        x: parent.width  / 2 - width  / 2
        y: parent.height / 2 - height / 2
        modal: true

        Label {
            padding: 10
            font.bold: true
            width: parent.width
            horizontalAlignment: Qt.AlignHCenter
            text: mSelectedRule >= 0 ? mRuleView.model.Get(mSelectedRule).fullName : ""
            color: Constants.mTextColor
        }
        MenuItem {
            text: qsTr("Edit...")
            font.pixelSize: Constants.mFontPixelSize
            onTriggered: mManageRuleDialog.editContact(mRuleView.model.Get(mSelectedRule))
        }
        MenuItem {
            text: qsTr("Remove")
            font.pixelSize: Constants.mFontPixelSize
            onTriggered: mRuleView.model.Remove(mSelectedRule)
        }
    }

    FocusScope // Vertical Box
    {
        id: row
        anchors.fill: parent

        FocusScope // Horizontal Box
        {
            id: mTopMenu

            readonly property double mSizeMod: 1.65
            height: Constants.mTextHeight * mSizeMod * 1.5

            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: mRuleView.top

            Button  {
                id: mBtnStartSearch

                onClicked: { 
                    mRuleView.model.Clear();
                    EnumRules.ScanRules();
                    mRuleView.model.PopulateRules(EnumRules);
                }

                anchors.top: parent.top
                anchors.left: parent.left
                //anchors.right: mTopSpacer.left // based on width
                anchors.bottom: parent.bottom
                
                // height: set by parent row
                width: mTopMenu.mSizeMod * Constants.mFontPixelSize * text.length

                text: "Start Search"
                contentItem: Text {
                    text: mBtnStartSearch.text
                    font.pointSize: mTopMenu.mSizeMod * Constants.mFontPixelSize
                    opacity: enabled ? 1.0 : 0.3
                    color: mBtnStartSearch.down ? "#c4dbff" : "#b8d3ff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Image {
                    id: mStartBackdrop
                    anchors.fill: parent
                    source:  parent.down ?
                            "qrc:///resource/backdrops/StartBox/RedTextBox.png" :
                            (parent.hovered ?
                                "qrc:///resource/backdrops/StartBox/DarkTextBox.png" :
                                "qrc:///resource/backdrops/StartBox/LightTextBox.png")
                }
            }

            Item {
                id: mTopSpacer
                width: parent.width - (mBtnStartSearch.width + mBtnClose.width)
            }

            Button  {
                id: mBtnClose
                width: parent.height
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                background: Image {
                    anchors.fill: parent
                    source: parent.hovered ? "qrc:///resource/icons/RedX_on.png" : 
                                             "qrc:///resource/icons/RedX_off.png"
                }

                onClicked: {
                    Qt.quit()
                }
            }
        }

        // ListView >> RulesView.qml (model: RulesModel.cpp >> RulesModel.qml && delegate: RulesDelegate)
        RulesView {
            id: mRuleView
            focus: true

            z:              -1
            width:          parent.width
            anchors.top:    mTopMenu.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom

            onPressAndHold: {
                mSelectedRule = index
                mContactMenu.Open()
            }
        }
    }

    RoundButton {
        text: qsTr("+")
        font.pixelSize: Constants.mFontPixelSize
        highlighted: true
        anchors.margins: 10
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onClicked: {
            mSelectedRule = -1
            mManageRuleDialog.createRule()
        }
    }

    background: Item {
        id: mBackground
        // x: mRuleView.x
        // y: mRuleView.y
        anchors.fill: parent
        z: -2

        Image {
            id: mBackdrop
            anchors.fill: parent
            source:  "qrc:///resource/pictures/BlueWallpaper.png"
        }
        FastBlur {
            anchors.fill: mBackdrop
            source: mBackdrop
            radius: 32
        }
    }
}
