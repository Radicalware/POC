
import QtQuick
import QtQuick.Controls

import Support

Dialog {
    id: mTop
    
    // -----------------------------------------------------------------------------------
    contentItem: NewRuleForm {
        id: mForm
    }

    standardButtons: Dialog.Ok | Dialog.Cancel
    // ---------------------------------------------------------------------------------------------------
    // Functions

    function createRule() {
        mForm.exeName.clear();
        mForm.fullPath.clear();
        mForm.ruleName.clear();
        mForm.description.clear();
        mForm.serviceName.clear();
        mForm.localAddress.clear();
        mForm.localPort.clear();
        mForm.remoteAddress.clear();
        mForm.remotePort.clear();

        mTop.title = qsTr("Add Rule");
        mTop.Open();
    }

    function editRule(Rule) {
        mForm.exeName.text = Rule.exeName;
        mForm.fullPath.text = Rule.fullPath;
        mForm.ruleName.text = Rule.ruleName;
        mForm.description.text = Rule.description;
        mForm.serviceName.text = Rule.serviceName;
        mForm.localAddress.text = Rule.localAddress;
        mForm.localPort.text = Rule.localPort;
        mForm.remoteAddress.text = Rule.remoteAddress;
        mForm.remotePort.text = Rule.remotePort;


        mTop.title = qsTr("Edit Rule");
        mTop.Open();
    }
    // ---------------------------------------------------------------------------------------------------
    // Data Members

    x: parent.width  / 2 - width  / 2
    y: parent.height / 2 - height / 2

    focus: true
    modal: true

    // Signals Listeners
    signal finished(string exeName, string fullPath, string ruleName, string description, string serviceName,
                    string localAddress, string localPort, string remoteAddress, string remotePort);

    // Slots (that call signals)
    onAccepted: finished(mForm.exeName.text, mForm.fullPath.text, mForm.ruleName.text, mForm.description.text, mForm.serviceName.text,
                            mForm.localAddress.text, mForm.LocalPort.text, mForm.remoteAddress.text, mForm.remotePort.text);
    // ---------------------------------------------------------------------------------------------------
}
