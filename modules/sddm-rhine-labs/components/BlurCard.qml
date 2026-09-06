import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property alias content: contentContainer.data
    property real blurAmount: 64
    property real brightness: 0.1
    property real saturation: 1.2
    property real borderRadius: 20 * Config.generalScale
    property var source: null
    property bool isCircular: false

    Item {
        id: backgroundClip
        anchors.fill: parent
        clip: true

        // We need a proxy item to handle the offset and capture the source
        Item {
            id: sourceProxy
            property point offset: (root.source && root.source.width > 0) ? root.mapToItem(root.source, 0, 0) : Qt.point(0, 0)
            x: -offset.x
            y: -offset.y
            width: root.source ? root.source.width : 0
            height: root.source ? root.source.height : 0
            visible: false

            // We use a ShaderEffectSource to capture the potentially hidden source
            ShaderEffectSource {
                anchors.fill: parent
                sourceItem: root.source
                live: true
                hideSource: false
            }
        }

        FastBlur {
            id: blurEffect
            anchors.fill: parent
            source: sourceProxy
            radius: root.blurAmount
            transparentBorder: true
        }

        // Apply brightness and saturation via a simple shader or overlay
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.brightness
            radius: root.isCircular ? width / 2 : root.borderRadius
        }
        
        // Masking for circular/rounded shape
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: maskItem
        }
    }

    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: root.isCircular ? width / 2 : root.borderRadius
            color: "black"
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        z: 2
    }
}
