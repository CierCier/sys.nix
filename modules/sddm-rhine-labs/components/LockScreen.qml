import QtQuick

Item {
    id: lockScreen
    signal loginRequested

    MouseArea {
        id: lockScreenMouseArea
        hoverEnabled: true
        anchors.fill: parent
        onClicked: lockScreen.loginRequested()
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_CapsLock) {
            root.capsLockOn = !root.capsLockOn;
        }

        if (event.key === Qt.Key_Escape) {
            event.accepted = false;
            return;
        } else {
            lockScreen.loginRequested();
        }
        event.accepted = true;
    }
}
