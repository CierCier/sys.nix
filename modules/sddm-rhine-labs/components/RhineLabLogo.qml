import QtQuick

Item {
    id: logoRoot
    width: 400
    height: 200

    property bool isIdle: true
    property real transitionProgress: isIdle ? 0.0 : 1.0
    property bool animationFinished: false

    onIsIdleChanged: {
        if (isIdle) {
            animationFinished = false;
            animatedLogo.currentFrame = 0;
            animatedLogo.playing = true;
        }
    }

    Behavior on transitionProgress {
        NumberAnimation {
            duration: 800
            easing.type: Easing.InOutQuad
        }
    }
    
    Behavior on x {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutExpo
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutExpo
        }
    }

    Image {
        id: whiteLogo
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        source: "../assets/RhineLogoAnimatedTransparentFinal.png"
        fillMode: Image.PreserveAspectFit
        opacity: logoRoot.isIdle && !logoRoot.animationFinished ? 0.0 : (1.0 - logoRoot.transitionProgress)
    }

    Image {
        id: loginLogo
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        source: "../assets/RhineLogoAnimatedFinalBlack.png"
        fillMode: Image.PreserveAspectFit
        opacity: logoRoot.transitionProgress
    }

    AnimatedImage {
        id: animatedLogo
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        source: "../assets/RhineLogoAnimatedTransparent.gif"
        fillMode: Image.PreserveAspectFit
        playing: logoRoot.isIdle
        cache: false
        opacity: 1.0 - logoRoot.transitionProgress

        onCurrentFrameChanged: {
            if (frameCount > 0 && currentFrame >= frameCount - 1) {
                logoRoot.animationFinished = true;
                playing = false;
            }
        }
    }
}
