import "."
import QtQuick
import SddmComponents
import QtQuick.Effects
import QtMultimedia
import "components"

Item {
    id: root
    state: Config.lockScreenDisplay ? "lockState" : "loginState"

    // TODO: Add own translations: https://github.com/sddm/sddm/wiki/Localization
    TextConstants {
        id: textConstants
    }

    property bool capsLockOn: false
    Component.onCompleted: {
        if (keyboard)
            capsLockOn = keyboard.capsLock;
    }
    onCapsLockOnChanged: {
        loginScreen.updateCapsLock();
    }

    states: [
        State {
            name: "lockState"
            PropertyChanges {
                target: lockScreen
                opacity: 1.0
            }
            PropertyChanges {
                target: loginScreen
                opacity: 0.0
            }
            PropertyChanges {
                target: loginScreen.loginContainer
                scale: 0.5
            }
            PropertyChanges {
                target: backgroundEffect
                blurMax: Config.lockScreenBlur
                brightness: Config.lockScreenBrightness
                saturation: Config.lockScreenSaturation
            }
        },
        State {
            name: "loginState"
            PropertyChanges {
                target: lockScreen
                opacity: 0.0
            }
            PropertyChanges {
                target: loginScreen
                opacity: 1.0
            }
            PropertyChanges {
                target: loginScreen.loginContainer
                scale: 1.0
            }
            PropertyChanges {
                target: backgroundEffect
                blurMax: Config.loginScreenBlur
                brightness: Config.loginScreenBrightness
                saturation: Config.loginScreenSaturation
            }
        }
    ]
    transitions: Transition {
        enabled: Config.enableAnimations
        PropertyAnimation {
            duration: 1600
            properties: "opacity"
            easing.type: Easing.OutExpo
        }
        PropertyAnimation {
            duration: 800
            properties: "blurMax"
        }
        PropertyAnimation {
            duration: 800
            properties: "brightness"
        }
        PropertyAnimation {
            duration: 800
            properties: "saturation"
        }
    }

    Item {
        id: mainFrame
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x
        y: geometry.y
        width: geometry.width
        height: geometry.height

        Rectangle {
            id: blackBackground
            anchors.fill: parent
            color: "black"
            visible: root.state === "lockState"
            z: 0
        }

        Item {
            id: backgroundImage
            anchors.fill: parent
            visible: root.state === "loginState"

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
                        backgroundImage.currentBgIndex = backgroundImage.nextBgIndex;
                        backgroundImage.nextBgIndex = (backgroundImage.nextBgIndex + 1) % backgroundImage.backgroundList.length;
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
                    source: "backgrounds/" + backgroundImage.backgroundList[backgroundImage.currentBgIndex]
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    mipmap: true
                }

                Image {
                    id: backdropSource2
                    anchors.fill: parent
                    source: "backgrounds/" + backgroundImage.backgroundList[backgroundImage.nextBgIndex]
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
        }
        MultiEffect {
            // Background effects
            id: backgroundEffect
            property real blurMax: 0
            source: slideshowShaderSource
            anchors.fill: parent
            visible: root.state === "loginState"
            blurEnabled: blurMax > 0
            blur: blurMax > 0 ? 1.0 : 0.0
            autoPaddingEnabled: false
        }

        Item {
            id: screenContainer
            anchors.fill: parent
            anchors.top: parent.top

            LockScreen {
                id: lockScreen
                z: root.state === "lockState" ? 2 : 1 // Fix tooltips from the login screen showing up on top of the lock screen.
                anchors.fill: parent
                focus: root.state === "lockState"
                enabled: root.state === "lockState"
                onLoginRequested: {
                    root.state = "loginState";
                    loginScreen.resetFocus();
                }
            }
            LoginScreen {
                id: loginScreen
                z: root.state === "loginState" ? 2 : 1
                anchors.fill: parent
                enabled: root.state === "loginState"
                opacity: 0.0
                onClose: {
                    root.state = "lockState";
                }
            }
        }
        
        RhineLabLogo {
            id: rhineLabLogo
            z: 10
            isIdle: root.state === "lockState"
            x: isIdle ? (mainFrame.width - width) / 2 : loginScreen.logoTargetX
            y: isIdle ? (mainFrame.height - height) / 2 : loginScreen.logoTargetY
        }
    }
}
