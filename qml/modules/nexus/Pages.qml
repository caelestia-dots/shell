import QtQuick
import Caelestia.Config
import qs.components
import qs.modules.nexus

Item {
    id: root

    required property NexusState nState

    property int lastPageIdx
    property int animOff
    property Item currentItem

    function loadPage(idx: int): void {
        if (currentItem)
            currentItem.destroy();

        const comp = PageCompRegistry.pageComps[idx] ?? PageCompRegistry.placeholderComp;
        const incubator = comp.incubateObject(container, {
            nState
        });

        const attach = () => {
            incubator.object.anchors.fill = container;
            currentItem = incubator.object;
        };

        if (incubator.status === Component.Ready)
            attach();
        else
            incubator.onStatusChanged = status => {
                if (status === Component.Ready)
                    attach();
            };
    }

    Item {
        id: container

        objectName: "PageContainer"
        anchors.fill: parent
        layer.enabled: opacity < 1
        Component.onCompleted: root.loadPage(root.nState.currentPageIdx)
    }

    Connections {
        function onCurrentPageIdxChanged(): void {
            switchAnim.complete();
            root.animOff = root.Tokens.padding.extraLarge * (root.nState.currentPageIdx > root.lastPageIdx ? 1 : -1);
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }

        target: root.nState
    }

    SequentialAnimation {
        id: switchAnim

        Anim {
            target: container
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
        ScriptAction {
            script: root.loadPage(root.nState.currentPageIdx)
        }
        PropertyAction {
            target: container.anchors
            property: "topMargin"
            value: root.animOff
        }
        PropertyAction {
            target: container.anchors
            property: "bottomMargin"
            value: -root.animOff
        }
        ParallelAnimation {
            Anim {
                target: container
                property: "opacity"
                from: 0
                to: 1
                type: Anim.SlowEffects
            }
            Anim {
                target: container.anchors
                properties: "topMargin,bottomMargin"
                to: 0
                type: Anim.SlowEffects
            }
        }
    }
}
