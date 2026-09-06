import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import SddmComponents

Item {
    id: loginScreen
    signal close
    signal toggleLayoutPopup

    state: "normal"
    property bool stateChanging: false
    readonly property bool isSelectingUser: state === "selectingUser"

    function safeStateChange(newState) {
        if (!stateChanging) {
            stateChanging = true;
            state = newState;
            stateChanging = false;
        }
    }

    onStateChanged: {
        if (state === "normal")
            resetFocus();
    }

    readonly property alias password: password
    readonly property alias loginButton: loginButton
    readonly property alias loginContainer: loginContainer
    readonly property alias loginLayout: formColumn

    property bool showKeyboard: !Config.virtualKeyboardStartHidden
    property bool foundUsers: userModel.count > 0

    property int sessionIndex: 0
    property int userIndex: 0
    property string userName: ""
    property string userRealName: ""
    property string userIcon: ""
    property bool userNeedsPassword: true

    readonly property real shellWidth: width
    readonly property real shellHeight: height
    readonly property real leftPaneWidth: Math.max(360, Math.min(loginShell.width * 0.47, loginShell.width - 460))
    readonly property real rightPaneWidth: loginShell.width - leftPaneWidth
    readonly property real backgroundBlendWidth: Math.max(140, width * 0.08)
    readonly property real logoTargetX: loginShell.x + (leftPaneWidth - rhineLogoGuide.width) / 2
    readonly property real logoTargetY: loginShell.y + (loginShell.height - rhineLogoGuide.height) / 2
    readonly property string paneBackgroundSource: Config.loginScreenBackground && Config.loginScreenBackground.length > 0 ? ("../backgrounds/" + Config.loginScreenBackground) : "../backgrounds/main.png"

    function login() {
        var user = foundUsers ? userName : userInput.text;
        if (user && user !== "") {
            sddm.login(user, password.text, sessionIndex);
        } else {
            loginMessage.warn(textConstants.promptUser || "Enter your user!", "error");
        }
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            loginContainer.scale = 0.0;
        }

        function onLoginFailed() {
            loginMessage.warn(textConstants.loginFailed || "Login failed", "error");
            password.text = "";
        }

        function onInformationMessage(message) {
            loginMessage.warn(message, "error");
        }
    }

    function updateCapsLock() {
        if (root.capsLockOn) {
            loginMessage.warn(textConstants.capslockWarning || "Caps Lock is on", "warning");
        } else {
            loginMessage.clear();
        }
    }

    function resetFocus() {
        if (!loginScreen.foundUsers) {
            userInput.input.forceActiveFocus();
        } else if (loginScreen.userNeedsPassword) {
            password.input.forceActiveFocus();
        } else {
            loginButton.forceActiveFocus();
        }
    }

    Rectangle {
        id: loginShell
        x: 0
        y: 0
        width: loginScreen.shellWidth
        height: loginScreen.shellHeight
        color: "#fbfaf7"
        clip: true

        Item {
            id: blendedBackdrop
            anchors.fill: parent

            property var backgroundList: ["bg0.png", "bg1.png", "bg2.png", "bg3.png", "bg4.png", "bg5.png"]
            property int currentBgIndex: 0
            property int nextBgIndex: 1

            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: crossFadeAnim.start()
            }

            SequentialAnimation {
                id: crossFadeAnim
                NumberAnimation {
                    target: backdropSource2
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: {
                        blendedBackdrop.currentBgIndex = blendedBackdrop.nextBgIndex;
                        blendedBackdrop.nextBgIndex = (blendedBackdrop.nextBgIndex + 1) % blendedBackdrop.backgroundList.length;
                        backdropSource2.opacity = 0.0;
                    }
                }
            }

            Item {
                id: slideshowContainer
                anchors.fill: parent
                visible: false
                
                Image {
                    id: backdropSource1
                    anchors.fill: parent
                    source: "../backgrounds/" + blendedBackdrop.backgroundList[blendedBackdrop.currentBgIndex]
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    mipmap: true
                }

                Image {
                    id: backdropSource2
                    anchors.fill: parent
                    source: "../backgrounds/" + blendedBackdrop.backgroundList[blendedBackdrop.nextBgIndex]
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    mipmap: true
                    opacity: 0.0
                }
            }

            ShaderEffectSource {
                id: slideshowShaderSource
                anchors.fill: parent
                sourceItem: slideshowContainer
                live: true
                hideSource: true
            }

            MultiEffect {
                anchors.fill: parent
                source: slideshowShaderSource
                blurEnabled: false
                brightness: 0.12
                saturation: -0.15
                colorization: 0.08
                colorizationColor: "#f5eedf"
                autoPaddingEnabled: false
            }
        }

        Rectangle {
            id: leftPane
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: loginScreen.leftPaneWidth
            color: "#fbfaf7"
        }

        Rectangle {
            id: horizontalFade
            width: loginScreen.backgroundBlendWidth
            anchors {
                left: leftPane.right
                top: parent.top
                bottom: parent.bottom
            }
            color: "transparent"

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "#fbfaf7"
                }
                GradientStop {
                    position: 0.35
                    color: "#80fbfaf7"
                }
                GradientStop {
                    position: 1.0
                    color: "#00fbfaf7"
                }
            }
        }

        Item {
            id: rhineLogoGuide
            width: 400
            height: 200
            anchors.centerIn: leftPane
        }

        Item {
            id: rightPane
            anchors {
                left: leftPane.right
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            clip: true

            Item {
                id: loginContainer
                width: Math.max(300, formColumn.width)
                height: userSelector.visible ? (userSelector.height + 18 * Config.generalScale + formColumn.height) : formColumn.height
                x: (rightPane.width - width) / 2
                y: userSelector.visible ? (rightPane.height - userSelector.height) / 2 : (rightPane.height - height) / 2
                scale: 0.5

                Behavior on scale {
                    enabled: Config.enableAnimations
                    NumberAnimation {
                        duration: 200
                    }
                }

                BlurCard {
                    id: avatarBlurCard
                    source: slideshowShaderSource
                    isCircular: true
                    width: userSelector.width + 12 * Config.generalScale
                    height: userSelector.height + 12 * Config.generalScale
                    anchors.centerIn: userSelector
                    visible: userSelector.visible
                    blurAmount: 80 * Config.generalScale
                    brightness: 0.1
                    z: -1
                }

                UserSelector {
                    id: userSelector
                    visible: loginScreen.foundUsers
                    width: Config.avatarActiveSize * Config.generalScale
                    height: Config.avatarActiveSize * Config.generalScale
                    anchors.horizontalCenter: parent.horizontalCenter
                    listUsers: loginScreen.isSelectingUser
                    enabled: true
                    orientation: "horizontal"
                    activeFocusOnTab: true

                    onOpenUserList: {
                        safeStateChange("selectingUser");
                    }

                    onCloseUserList: {
                        safeStateChange("normal");
                        loginScreen.resetFocus();
                    }

                    onUserChanged: function(index, name, realName, icon, needsPassword) {
                        if (loginScreen.foundUsers) {
                            loginScreen.userIndex = index;
                            loginScreen.userName = name;
                            loginScreen.userRealName = realName;
                            loginScreen.userIcon = icon;
                            loginScreen.userNeedsPassword = needsPassword;
                        }
                    }
                }

                BlurCard {
                    id: formBlurCard
                    source: slideshowShaderSource
                    width: formColumn.width + 24 * Config.generalScale
                    height: formColumn.height + 24 * Config.generalScale
                    anchors.centerIn: formColumn
                    borderRadius: 18 * Config.generalScale
                    blurAmount: 80 * Config.generalScale
                    brightness: 0.1
                    z: -1
                }

                Column {
                    id: formColumn
                    width: Config.passwordInputWidth * Config.generalScale + (loginButton.visible ? Config.passwordInputHeight * Config.generalScale + Config.loginButtonMarginLeft : 0)
                    spacing: 12 * Config.generalScale
                    anchors {
                        top: userSelector.visible ? userSelector.bottom : parent.top
                        topMargin: userSelector.visible ? 64 * Config.generalScale : 0
                        horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        id: activeUserName
                        visible: loginScreen.foundUsers
                        width: Config.passwordInputWidth * Config.generalScale
                        height: Config.passwordInputHeight * Config.generalScale
                        radius: 10 * Config.generalScale
                        color: "transparent"
                        border.width: 0
                        border.color: "#d9d1c6"
                        x: (parent.width - width) / 2

                        Text {
                            anchors.centerIn: parent
                            text: loginScreen.userRealName || loginScreen.userName || ""
                            font.family: Config.usernameFontFamily
                            font.weight: Config.usernameFontWeight
                            font.pixelSize: Config.usernameFontSize * Config.generalScale
                            color: Config.usernameColor
                        }
                    }

                    Input {
                        id: userInput
                        visible: !loginScreen.foundUsers
                        width: Config.passwordInputWidth * Config.generalScale
                        icon: Config.getIcon("user-default")
                        placeholder: (textConstants && textConstants.userName) ? textConstants.userName : "Username"
                        isPassword: false
                        splitBorderRadius: false
                        enabled: true
                        x: (parent.width - width) / 2

                        onAccepted: {
                            loginScreen.login();
                        }
                    }

                    Item {
                        id: passwordRow
                        width: parent.width
                        height: Math.max(password.height, loginButton.height)

                        Input {
                            id: password
                            width: Config.passwordInputWidth * Config.generalScale
                            enabled: loginScreen.state === "normal"
                            visible: loginScreen.userNeedsPassword || !loginScreen.foundUsers
                            icon: Config.getIcon(Config.passwordInputIcon)
                            placeholder: (textConstants && textConstants.password) ? textConstants.password : "Password"
                            isPassword: true
                            splitBorderRadius: loginButton.visible
                            anchors.left: parent.left

                            onAccepted: {
                                loginScreen.login();
                            }
                        }

                        IconButton {
                            id: loginButton
                            visible: !Config.loginButtonHideIfNotNeeded || !loginScreen.userNeedsPassword
                            enabled: loginScreen.state !== "selectingUser"
                            activeFocusOnTab: true
                            icon: Config.getIcon(Config.loginButtonIcon)
                            label: textConstants.login ? textConstants.login : "Login"
                            showLabel: Config.loginButtonShowTextIfNoPassword && !loginScreen.userNeedsPassword
                            tooltipText: !Config.tooltipsDisableLoginButton && (!Config.loginButtonShowTextIfNoPassword || loginScreen.userNeedsPassword) ? (textConstants.login || "Login") : ""
                            iconSize: Config.loginButtonIconSize
                            fontFamily: Config.loginButtonFontFamily
                            fontSize: Config.loginButtonFontSize
                            fontWeight: Config.loginButtonFontWeight
                            contentColor: Config.loginButtonContentColor
                            activeContentColor: Config.loginButtonActiveContentColor
                            backgroundColor: Config.loginButtonBackgroundColor
                            backgroundOpacity: Config.loginButtonBackgroundOpacity
                            activeBackgroundColor: Config.loginButtonActiveBackgroundColor
                            activeBackgroundOpacity: Config.loginButtonActiveBackgroundOpacity
                            borderSize: Config.loginButtonBorderSize
                            borderColor: Config.loginButtonBorderColor
                            borderRadiusLeft: password.visible ? Config.loginButtonBorderRadiusLeft : Config.loginButtonBorderRadiusRight
                            borderRadiusRight: Config.loginButtonBorderRadiusRight
                            height: Config.passwordInputHeight * Config.generalScale
                            anchors.right: parent.right

                            onClicked: {
                                loginScreen.login();
                            }
                        }
                    }


                    Text {
                        id: loginMessage
                        property bool capslockWarning: false
                        width: Config.passwordInputWidth * Config.generalScale
                        visible: text !== "" && (capslockWarning ? loginScreen.userNeedsPassword : true)
                        opacity: visible ? 1.0 : 0.0
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Config.warningMessageFontSize * Config.generalScale
                        font.family: Config.warningMessageFontFamily
                        font.weight: Config.warningMessageFontWeight
                        color: Config.warningMessageNormalColor
                        x: (parent.width - width) / 2

                        Behavior on opacity {
                            enabled: Config.enableAnimations
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        function warn(message, type) {
                            clear();
                            text = message;
                            color = type === "error" ? Config.warningMessageErrorColor : (type === "warning" ? Config.warningMessageWarningColor : Config.warningMessageNormalColor);
                            if (message === (textConstants.capslockWarning || "Caps Lock is on"))
                                capslockWarning = true;
                        }

                        function clear() {
                            text = "";
                            capslockWarning = false;
                        }

                        Component.onCompleted: {
                            if (root.capsLockOn)
                                loginMessage.warn(textConstants.capslockWarning || "Caps Lock is on", "warning");
                        }
                    }
                }
            }

            Item {
                id: footerRow
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 28 * Config.generalScale
                    bottomMargin: 20 * Config.generalScale
                }
                width: 400 * Config.generalScale
                height: Config.menuAreaButtonsSize * Config.generalScale

                BlurCard {
                    id: footerBlurCard
                    source: slideshowShaderSource
                    anchors.fill: parent
                    anchors.margins: -14 * Config.generalScale
                    borderRadius: 14 * Config.generalScale
                    blurAmount: 80 * Config.generalScale
                    brightness: 0.1
                    z: -1
                }

                MenuArea {
                    anchors.fill: parent
                }
            }
        }
    }

    CVKeyboard {}

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (Config.lockScreenDisplay)
                loginScreen.close();
            password.text = "";
        } else if (event.key === Qt.Key_CapsLock) {
            root.capsLockOn = !root.capsLockOn;
        }
        event.accepted = true;
    }

    MouseArea {
        id: closeUserSelectorMouseArea
        z: -1
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (loginScreen.state === "selectingUser")
                safeStateChange("normal");
        }

        onWheel: function(event) {
            if (loginScreen.state === "selectingUser") {
                if (event.angleDelta.y < 0)
                    userSelector.nextUser();
                else
                    userSelector.prevUser();
            }
        }
    }
}
