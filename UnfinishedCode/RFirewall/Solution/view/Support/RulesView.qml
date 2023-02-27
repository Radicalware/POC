
import QtQuick
import QtQuick.Controls

// todo fix: Can't use both c++ and qml versions at the same time
import Backend        // Uses the .cpp version
//import "../Backend" // Uses the .qml version
import Constants

ListView {
    id: mTop

    signal pressAndHold(int index)

    width:  600
    height: 900

    focus: true
    boundsBehavior: Flickable.StopAtBounds

    // We take the FirstCharacter from "fullName" and put it at the top of each section
    section.property: "exeName"
    section.criteria: ViewSection.FirstCharacter
    section.delegate: SectionDelegate {
        width: mTop.width
        //height: mTop.mRulesModel.items.length * height
    }

    // This sets the structure of the RulesModel
    delegate: RulesDelegate {
        id: delegate
        width: mTop.width
        onPressAndHold: mTop.pressAndHold(index)
    }

    // RulesModel.qml (has some pre-input data) which inherits from RulesModel.cpp which has even more
    model: RulesModel {
        id: mRulesModel // IDs can't start with an uppercase character
    }

    ScrollBar.vertical: ScrollBar {  }

    Component.onCompleted: {
        console.log("init RulesView.qml")
    }
}
