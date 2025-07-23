import QtQuick
import qs.Common

Item {
    id: root
    
    required property Item target
    property int direction: Anims.direction.fadeOnly

    function show() { _apply(true) }
    function hide() { _apply(false) }

    function _apply(showing) {
        const off = Anims.slidePx
        let fromX = 0
        let toX = 0
        switch(direction) {
        case Anims.direction.fromLeft: fromX = -off; toX = 0; break
        case Anims.direction.fromRight: fromX = off; toX = 0; break
        default: fromX = 0; toX = 0;
        }

        if (showing) {
            target.x = fromX
            target.opacity = 0
            target.visible = true
            animX.from = fromX; animX.to = toX
            animO.from = 0; animO.to = 1
        } else {
            animX.from = target.x; animX.to = (direction === Anims.direction.fromLeft ? -off :
                                              direction === Anims.direction.fromRight ? off : 0)
            animO.from = target.opacity; animO.to = 0
        }
        seq.restart()
    }

    SequentialAnimation {
        id: seq
        ParallelAnimation {
            NumberAnimation { 
                id: animX
                target: root.target
                property: "x"
                duration: Anims.durMed
                easing.type: Easing.OutCubic
            }
            NumberAnimation { 
                id: animO
                target: root.target
                property: "opacity"
                duration: Anims.durShort
            }
        }
        ScriptAction { script: if (root.target.opacity === 0) root.target.visible = false }
    }
}