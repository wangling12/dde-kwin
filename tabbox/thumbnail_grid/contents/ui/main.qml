import QtQuick 2.0
import QtQuick.Window 2.0
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kwin 2.0 as KWin

// https://techbase.kde.org/Development/Tutorials/KWin/WindowSwitcher
KWin.Switcher {
    id: tabBox
    currentIndex: itemsView.currentIndex

    Window {
        id: dialog
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        color: "transparent"

        //NOTE: this is the *current* screen, not the *primary* screen
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        onVisibleChanged: {
            if (visible) {
                dialogMainItem.calculateColumnCount();
            } else {
                itemsView.highCount = 0;
            }
        }

        Component.onCompleted: {
            if (dde) {
                dde.enableDxcb(dialogMainItem)
            }
        }

        width: dialogMainItem.width
        height: dialogMainItem.height

        Rectangle {
            id: dialogMainItem

            QtObject {
                id: constants

                readonly property int minItemBox: 128
                readonly property int defaultBoxMargin: 32
                readonly property int popupPadding: 70

                readonly property int columnSpacing: 20
                readonly property int rowSpacing: 20
                readonly property int minItemsEachRow: 7
                readonly property int maxRows: 2
            }

            anchors.margins: 0
            color: "#4cffffff"
            radius: 6
            antialiasing: true
            border.width: 1
            border.color: "#19000000"

            readonly property int maxWidth: tabBox.screenGeometry.width - constants.popupPadding * 2
            property int maxHeight: tabBox.screenGeometry.height * 0.7 

            property real screenFactor: tabBox.screenGeometry.width / tabBox.screenGeometry.height
            property int maxGridColumnsByWidth: Math.floor(maxWidth / itemsView.cellWidth)

            property int gridColumns: maxGridColumnsByWidth
            property int gridRows: 1

            property int optimalWidth: itemsView.cellWidth * gridColumns
            property int optimalHeight: itemsView.cellHeight * gridRows

            property bool canStretchX: false
            property bool canStretchY: false
            width: Math.min(Math.max(itemsView.cellWidth, optimalWidth), maxWidth)
            height: Math.min(Math.max(itemsView.cellHeight, optimalHeight), maxHeight)

            clip: true

            function calculateColumnCount() {
                var count = itemsView.count
                var item_need_scale = false
                var spacing = constants.defaultBoxMargin * 2 + 4
                var item_width = constants.minItemBox + constants.columnSpacing
                var maxWidth = tabBox.screenGeometry.width - constants.popupPadding * 2

                var max_items_each_row = Math.floor((maxWidth - spacing) / item_width);
                if (max_items_each_row < constants.minItemsEachRow && count > max_items_each_row) {
                    item_need_scale = true;
                    max_items_each_row = Math.min(count, constants.minItemsEachRow);
                }

                if (max_items_each_row * constants.maxRows < count) {
                    max_items_each_row = Math.floor(count / constants.maxRows);
                    item_need_scale = true;
                }

                if (item_need_scale) {
                    item_width = maxWidth / max_items_each_row 
                }

                gridColumns = Math.min(max_items_each_row, count);
                gridRows = Math.ceil(count / max_items_each_row);
                if (gridRows == 0) gridRows = 1;

                optimalWidth = item_width * gridColumns + spacing
                optimalHeight = item_width * gridRows + spacing

                itemsView.thumbnailWidth = item_width;
                itemsView.thumbnailHeight = item_width;

                //console.log('------------------ optimalHeight: ' + optimalHeight + 
                    //', optimalWidth: ' + optimalWidth +
                    //', max_items_each_row: ' + max_items_each_row +
                    //', gridColumns: ' + gridColumns +
                    //', item width: ' + item_width + ', count: ' + count +
                    //', need scale: ' + item_need_scale + 
                    //', maxWidth: ' + maxWidth);
            }


            property bool mouseEnabled: false
            MouseArea {
                id: mouseDetector
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: dialogMainItem.mouseEnabled = true
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                radius: 6
                antialiasing: true
                border.width: 1
                border.color: "#19000000"


                Component {
                    id: highlight
                    Rectangle {
                        width: itemsView.cellWidth
                        height: itemsView.cellHeight

                        color: "#01bdff"
                        radius: 4

                        x: dialog.visible ? itemsView.currentItem.x : 0
                        y: dialog.visible ? itemsView.currentItem.y : 0

                        Behavior on x { SmoothedAnimation { easing.type: Easing.InOutCubic; duration: 200 } }
                        Behavior on y { SmoothedAnimation { easing.type: Easing.InOutCubic; duration: 200 } }
                    }
                }


                GridView {
                    id: itemsView
                    model: tabBox.model
                    // interactive: false // Disable drag to scroll

                    anchors.fill: parent
                    anchors.margins: constants.defaultBoxMargin

                    property int thumbnailWidth: constants.minItemBox
                    property int thumbnailHeight: constants.minItemBox

                    cellWidth: thumbnailWidth 
                    cellHeight: thumbnailHeight 

                    highlight: highlight
                    highlightFollowsCurrentItem: false

                    // allow expansion on increasing count
                    property int highCount: 0
                    onCountChanged: {
                        if (highCount != count) {
                            dialogMainItem.calculateColumnCount();
                            highCount = count;
                        }
                    }


                    delegate: Item {
                        z: 1
                        width: itemsView.cellWidth
                        height: itemsView.cellHeight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                parent.select()
                            }
                        }

                        function select() {
                            itemsView.currentIndex = index;
                            itemsView.currentIndexChanged(itemsView.currentIndex);
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"

                            //color: index == itemsView.currentIndex ? "#01bdff" : "transparent"
                            //radius: 4

                            /*
                             Rectangle {
                                 anchors.margins: 10
                                 anchors.fill: parent
                                 z: 1
                                 color: "transparent"

                                 PlasmaCore.WindowThumbnail {
                                     z: 1
                                     winId: windowId
                                     clip: true
                                     anchors.fill: parent
                                 }
                             }
                             */

                            Rectangle {
                                anchors.margins: constants.columnSpacing / 2
                                anchors.fill: parent
                                z: 2
                                color: "transparent"

                                QIconItem {
                                    id: iconItem
                                    //FIXME: this is not the icon we want, seems to be a bug of kwin
                                    icon: model.icon
                                    clip: true
                                    anchors.fill: parent
                                    smooth: true
                                    state: index == itemsView.currentIndex ? QIconItem.ActiveState : QIconItem.DefaultState
                                }

                                // shadow for icon
                                DropShadow {
                                    anchors.fill: iconItem
                                    horizontalOffset: 0
                                    verticalOffset: 8
                                    radius: 8.0
                                    samples: 17
                                    color: "#32000000"
                                    source: iconItem
                                }
                            }
                        }
                    } // GridView.delegate

                    Connections {
                        target: tabBox
                        onCurrentIndexChanged: {
                            itemsView.currentIndex = tabBox.currentIndex
                        }
                    }

                    // keyNavigationEnabled: true // Requires: Qt 5.7 and QtQuick 2.? (2.7 didn't work).
                    // keyNavigationWraps: true // Requires: Qt 5.7 and QtQuick 2.? (2.7 didn't work).

                } // GridView
            } // Dialog.mainItem
        }
    } // Dialog
}
