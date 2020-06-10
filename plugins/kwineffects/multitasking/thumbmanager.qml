import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2
import QtQuick.Window 2.0
import com.deepin.kwin 1.0
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kwin 2.0 as KWin

Rectangle {
    id: root
    width: Screen.width;
    height: Screen.height;
    color: "transparent"

    Rectangle {
        id: background
        x: 0
        y: 0
        height: root.height
        width: {
            var allWitdh = 0;
            for (var i = 0; i < $Model.numScreens(); ++i) {
                var geom = $Model.screenGeometry(i);
                allWitdh += geom.width;
            }
            return allWitdh;
        }
        color: "black"
        opacity: 0.6
    }

    function log(msg) {
        manager.debugLog(msg)
    }

    signal qmlRequestMove2Desktop(int screen, int desktop, var winId);
    signal resetModel();
    signal qmlCloseMultitask();
    signal qmlRemoveWindowThumbnail(int screen, int desktop, int index, var winId);

    Component {
        id: windowThumbnailView;
        Rectangle {
            color: "red";
            GridLayout {
                id:windowThumbnailViewGrid
                x: desktopThumbnailWidth/7;
                y: desktopThumbnailHeight/10;
                width: desktopThumbnailWidth*5/7;
                height: desktopThumbnailHeight*8/10;
                columns : $Model.getCalculateColumnsCount(screen,desktop);
                Repeater {
                    id: windowThumbnailRepeater
                    model: $Model.windows(screen, desktop);
                    PlasmaCore.WindowThumbnail {
                        Layout.fillWidth: true;
                        Layout.fillHeight: true;
                        winId: modelData;

                        //zhd add
                        id:winAvatar
                        property var draggingdata: winId
                        property bool dropreceived : false

                        property int dragingIndex:index
                        Drag.keys: ["DraggingWindowAvatar"];  //for holdhand
                        Drag.active:  avatarMousearea.drag.active
                        Drag.hotSpot {
                            x: width/2
                            y: height/2
                        }
                        MouseArea{ //zhd add   for drag window
                            id:avatarMousearea
                            anchors.fill:parent
                            drag.target:winAvatar
                            drag.smoothed :true

                            onPressed: {
                                 winAvatar.Drag.hotSpot.x = mouse.x;
                                 winAvatar.Drag.hotSpot.y = mouse.y;
                            }
                            drag.onActiveChanged: {
                                if (!avatarMousearea.drag.active) {
                                    console.log('------- release on ' + avatarMousearea.drag.target)
                                    winAvatar.Drag.drop();
                                }
                            }
                            states: State {
                                when: avatarMousearea.drag.active;
                                ParentChange {
                                    target: winAvatar;
                                    parent: root;
                                }

                                PropertyChanges {
                                    target: winAvatar;
                                    z: 100;

                                }
                                // AnchorChanges {
                                //     target: winAvatar;
                                //     anchors.horizontalCenter: undefined
                                //     anchors.verticalCenter: undefined
                                // }
                            }
                        }
                        //zhd add end
                    }
                }
                Connections {
                    target: root
                    onResetModel: {
                        windowThumbnailViewGrid.columns = $Model.getCalculateColumnsCount(screen,desktop);
                        windowThumbnailRepeater.model = $Model.windows(screen, desktop);
                        windowThumbnailRepeater.update();
                        //console.log(" model is changed !!!!!!!!!!")
                    }
                }
            }
        }
    }

    Component {
        id: desktopThumbmailView;
        Rectangle {
            y:20
            width: screenWidth;
            height: parent.height;
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    qmlCloseMultitask();
                }
            }
            ListView {
                id: view
                width: 0;
                height: parent.height;
                orientation: ListView.Horizontal;
                model: $Model
                interactive : false;
                clip: true;
                spacing: manager.thumbSize.width/10
                delegate: Rectangle {
                    id: thumbDelegate;
                    width: manager.thumbSize.width*9/10;
                    height: manager.thumbSize.height;
                    color: "transparent"

                    property bool isDesktopHightlighted: index === $Model.currentDeskIndex

                    DesktopThumbnail {
                        id: desktopThumbnail;
                        desktop: index + 1;
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        property var originParent: view


                        width: thumbDelegate.width
                        height: thumbDelegate.height
                        MouseArea {
                            id: desktopThumbMouseArea
                            anchors.fill: parent;
                            hoverEnabled: true;

                            onClicked: {
                                $Model.setCurrentIndex(index);
                            }

                            drag.target: desktopThumbnail;
                            onReleased: {
                                if (manager.desktopCount == 1) {
                                    return
                                }
                            }
                            onPressed: {
                                desktopThumbnail.Drag.hotSpot.x = mouse.x;
                                desktopThumbnail.Drag.hotSpot.y = mouse.y;
                            }
                            drag.onActiveChanged: {
                                if (!desktopThumbMouseArea.drag.active) {
                                    log('------- release ws on ' + thumbDelegate.Drag.target)
                                    desktopThumbnail.Drag.drop();
                                }
                            }

                            onEntered: {
                                if ($Model.rowCount() != 1) {
                                    closeBtn.visible = true;
                                }
                            }

                            onExited: {
                                closeBtn.visible = false;
                            }
                        }
                        property bool pendingDragRemove: false
                        Drag.keys: ["workspaceThumb"];
                        Drag.active: manager.desktopCount > 1 && desktopThumbMouseArea.drag.active
                        Drag.hotSpot {
                            x: width/2
                            y: height/2
                        }

                        states: [State {
                                when: desktopThumbnail.Drag.active;
                                ParentChange {
                                    target: desktopThumbnail;
                                    parent: root;
                                }

                                PropertyChanges {
                                    target: desktopThumbnail;
                                    z: 100;
                                }
                                AnchorChanges {
                                    target: desktopThumbnail;
                                    anchors.horizontalCenter: undefined
                                    anchors.verticalCenter: undefined
                                }
                            },
                            State {
                                name: "isDesktopHightlighted"
                                when: isDesktopHightlighted
                                PropertyChanges {
                                    target: winThumrect
                                    border.width: 3;
                                }
                            }]


                        //window thumbnail
                        Loader {
                            id: winThumLoader
                            sourceComponent: windowThumbnailView
                            property int thumbnailWidth: 50;
                            property int thumbnailHeight: 50;
                            property int screen: currentScreen;
                            property int desktopThumbnailWidth:desktopThumbnail.width
                            property int desktopThumbnailHeight:desktopThumbnail.height
                            property int desktop: desktopThumbnail.desktop;
                        }

                        Rectangle {
                            id: closeBtn;
                            anchors.right: parent.right;
                            width: closeBtnIcon.width;
                            height: closeBtnIcon.height;
                            color: "transparent";
                            property int desktop: desktopThumbnail.desktop;
                            visible: false;

                            Image {
                                id: closeBtnIcon;
                                source: "qrc:///icons/data/close_normal.svg"
                            }

                            MouseArea {
                                anchors.fill: closeBtn;
                                onClicked: {
                                    $Model.remove(index);
                                }
                            }

                            Connections {
                                target: view;
                                onCountChanged: {
                                    closeBtn.visible = false;
                                }
                            }
                        }

                        Rectangle {
                            id:winThumrect;
                            width: parent.width;
                            height: parent.height;
                            border.color: "lightskyblue";
                            border.width: 0;
                            color: "transparent";
                        }
                    }

                    DropArea {
                        id: workspaceThumbDrop
                        anchors.fill: parent;
                        property int designated: index + 1;
                        property var originParent: view

                        z: 1
                        keys: ['workspaceThumb','DraggingWindowAvatar','DragwindowThumbnailitemdata']  //  zhd change for drop a window


                        onDropped: {
                            /* NOTE:
                            * during dropping, PropertyChanges is still in effect, which means
                            * drop.source.parent should not be Loader
                            * and drop.source.z == 100
                            */
                            log("----------- workspaceThumb onDrop")

                            if (drop.keys[0] === 'workspaceThumb') {
                                var from = drop.source.desktop
                                var to = workspaceThumbDrop.designated
                                if (workspaceThumbDrop.designated == drop.source.desktop && drop.source.pendingDragRemove) {
                                        //FIXME: could be a delete operation but need more calculation
                                        log("----------- workspaceThumbDrop: close desktop " + from)
                                        $Model.remove(index);
                                } else {
                                    if (from == to) return
                                    if(drop.source.originParent != originParent) return
                                    log("from:"+from + " to:"+to)
                                    $Model.move(from-1, to-1);
                                    $Model.refreshWindows();
                                    resetModel()
                                    log("----------- workspaceThumbDrop: reorder desktop ")
                                }
                            }
                            if(drop.keys[0]==="DraggingWindowAvatar" || drop.keys[0]==="DragwindowThumbnailitemdata"){  //zhd add

                                console.log("DraggingWindowAvatar :Droppsource   " +drag.source.draggingdata +"desktop index:" + desktopThumbnail.desktop + "current screen: "+ currentScreen);
                                qmlRequestMove2Desktop(currentScreen,desktopThumbnail.desktop,drag.source.draggingdata);
                                grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                                grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                                grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                                grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
                                windowThumbnail.model = $Model.windows(currentScreen, $Model.currentIndex()+1);

                                drag.source.dropreceived=true
                            }
                        }

                        onEntered: {
                            if (drag.keys[0] === 'workspaceThumb') {
                             
                            }
                            //console.log('------[workspaceThumbDrop]: Enter ' + workspaceThumbDrop.designated + ' from ' + drag.source + ', keys: ' + drag.keys + ', accept: ' + drag.accepted)
                        }

                        onExited: {
                            console.log("----------- workspaceThumb onExited")
                            if (drag.source.pendingDragRemove) {
                                hint.visible = false
                                drag.source.pendingDragRemove = hint.visible
                            }

                        }

                        onPositionChanged: {
                            if (drag.keys[0] === 'workspaceThumb') {
                                var diff = workspaceThumbDrop.parent.y - drag.source.y
                       //         log('------ ' + workspaceThumbDrop.parent.y + ',' + drag.source.y + ', ' + diff + ', ' + drag.source.height/2)
                                if (diff > 0 && diff > drag.source.height/2) {
                                    hint.visible = true
                                } else {
                                    hint.visible = false
                                }
                                drag.source.pendingDragRemove = hint.visible
                            }
                        }

                        Rectangle {
                            id: hint
                            visible: false
                            anchors.fill: parent
                            color: "transparent"

                            Text {
                                text: qsTr("Drag upwards to remove")
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: parent.height * 0.572

                                font.family: "Helvetica"
                                font.pointSize: 14
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }

                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.lineWidth = 0.5;
                                    ctx.strokeStyle = "rgba(255, 255, 255, 0.6)";

                                    var POSITION_PERCENT = 0.449;
                                    var LINE_START = 0.060;

                                    ctx.beginPath();
                                    ctx.moveTo(width * LINE_START, height * POSITION_PERCENT);
                                    ctx.lineTo(width * (1.0 - 2.0 * LINE_START), height * POSITION_PERCENT);
                                    ctx.stroke();
                                }
                            }
                        }
                    }
                }

                //center
                onCountChanged: {
                    view.width = manager.thumbSize.width * count;
                    view.x = (parent.width - view.width) / 2;
                    plus.visible = count < 4;
                    grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                    grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                    grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                    grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
                    //default value 1
                    windowThumbnail.model = $Model.windows(currentScreen, $Model.currentIndex()+1);
                    bigWindowThrumbContainer.curdesktop=$Model.currentIndex()+1 //zhd add
                    plus.visible = (count < 4) 
                }


                Connections {
                    target: $Model;
                    onCurrentIndexChanged: {
                        grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                        grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                        grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                        grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
                        windowThumbnail.model = $Model.windows(currentScreen, currentIndex + 1);

                        bigWindowThrumbContainer.curdesktop=$Model.currentIndex()+1 //zhd add 
                    }
                }
            }

            Rectangle {
                id: plus
                enabled: visible
                color: "#33ffffff"

                anchors.top: parent.top;
                anchors.right: parent.right;
                width: manager.thumbSize.width;
                height: manager.thumbSize.height;
                radius: width > 120 ? 30: 15

                Connections {
                    target: root
                    onWidthChanged: {
                        var r = manager.calculateDesktopThumbRect(0)
                        plus.x = manager.containerSize.width - 200
                        plus.y = r.y + (r.height - plus.height)/2
                        log(' ------------ width changed ' + root.width)
                    }
                }
                Image {
                    z: 1
                    id: background
                    //source: backgroundManager.defaultNewDesktopURI
                    anchors.fill: parent
                    visible: false //disable now

                    opacity: 0.0
                    Behavior on opacity {
                        PropertyAnimation { duration: 200; easing.type: Easing.InOutCubic }
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            x: background.x
                            y: background.y
                            width: background.width
                            height: background.height
                            radius: 6
                        }
                    }
                }

                Canvas {
                    z: 2
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        var plus_size = 20.0
                        ctx.lineWidth = 2
                        ctx.strokeStyle = "rgba(255, 255, 255, 1.0)";

                        ctx.beginPath();
                        ctx.moveTo((width - plus_size)/2, height/2);
                        ctx.lineTo((width + plus_size)/2, height/2);

                        ctx.moveTo(width/2, (height - plus_size)/2);
                        ctx.lineTo(width/2, (height + plus_size)/2);
                        ctx.stroke();
                    }
                }

//                Behavior on x {
//                    enabled: animateLayouting
//                    PropertyAnimation { duration: 300; easing.type: Easing.Linear }
//                }

                MouseArea {
                    anchors.fill: parent
                    //hoverEnabled: true
                    onClicked: {
                        $Model.append();
                    }
                    onEntered: {
                        //backgroundManager.shuffleDefaultBackgroundURI()
                        background.opacity = 0.6
                    }

                    onExited: {
                        background.opacity = 0.0
                    }
                }
                DropArea {
                    anchors.fill: plus;
                    onEntered: console.log("entered")
                    keys:['needgivemeakey']   //????
                    onDropped: {
                        var winId = drag.source.winId;
                        $Model.append();
                        var currentDesktop = $Model.rowCount();
                        qmlRequestMove2Desktop(currentScreen, currentDesktop, winId);
                        $Model.setCurrentIndex(currentDesktop - 1);
                    }
                }
            } //~ plus button

            //window thumbnail


            Rectangle{
                id: bigWindowThrumbContainer
                x: 0
                y: view.y + view.height;
                width: screenWidth  //  other area except grid  can receove
                height: screenHeight - view.height-35;
                color:"transparent"

                property int curdesktop:1
                z:1

                //zhd add for receive window thrumbnail
                DropArea { 
                    id: workspaceThumbnailDropArea
                    anchors.fill: parent
                    keys: ['DraggingWindowAvatar']

                    onDropped: {
                        //console.log("bigWindowThrumbContainer droped");

                        var from = drop.source.desktop

                        if(from!=bigWindowThrumbContainer.curdesktop && bigWindowThrumbContainer.curdesktop!=null && drop.keys[0]==="DraggingWindowAvatar"){

                            console.log("DraggingWindow on big view  :Dropsource:" +drag.source.draggingdata +"  desktop index:" +  bigWindowThrumbContainer.curdesktop+ "  current screen: "+ currentScreen);
                            qmlRequestMove2Desktop(currentScreen,bigWindowThrumbContainer.curdesktop,drag.source.draggingdata);

                            grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                            grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                            grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                            grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
                            windowThumbnail.model = $Model.windows(currentScreen, $Model.currentIndex()+1);
                        }

                    }
                    onEntered: {
                        drag.accepted=true;
                        console.log("bigWindowThrumbContainer enter");

                    }
                }
                //zhd add end

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                       qmlCloseMultitask();
                    }
                }
                GridLayout {
                    id:grid
                    width: screenWidth*5/7;
                    height: screenHeight - view.height-35;
                    anchors.centerIn: parent;
                    columns : $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);

                    Repeater {
                        id: windowThumbnail;
                        //model: $Model.windows(currentScreen)
                        PlasmaCore.WindowThumbnail {
                            id:windowThumbnailitem
                            property bool isHightlighted: winId == $Model.currentWindowThumbnail
                            Layout.fillWidth: true;
                            Layout.fillHeight: true;

                            winId: modelData;
                            property var draggingdata: winId
                            property bool  dropreceived:false
                            


                            Drag.keys:["DragwindowThumbnailitemdata"];
                            Drag.active: windowThumbnailitemMousearea.drag.active
                            Drag.hotSpot {
                                x:0
                                y:0
                            }

                            Rectangle {
                                id:backgroundrect;
                                width: parent.width;
                                height: parent.height;
                                border.color: "lightgray";
                                border.width: 0;
                                color: "transparent";
                            }
                          
                            MouseArea {
                                id:windowThumbnailitemMousearea
                                anchors.fill: windowThumbnailitem
                                acceptedButtons: Qt.LeftButton| Qt.RightButton;
                                hoverEnabled: true;
                                property variant mouseDragStart:"1,1"

                                property bool dropreceived : false


                                onEntered: {
                                    $Model.setCurrentSelectIndex(modelData);
                                    closeClientBtn.visible = true;
                                }
                              
                                onClicked: {
                                    $Model.setCurrentSelectIndex(modelData);
                                    $Model.windowSelected( modelData );
                                }
                                onExited: {
                                     closeClientBtn.visible = false;
                                     //pressDelayTimer.running=false
                                }
                                // Timer {
                                //     id: pressDelayTimer

                                //     interval: 500; running: false; repeat: false
                                //     onTriggered: {
                                        
                                        
                                //     }
                                // }
                                onPressed:{
                                    mouseDragStart.x+=mouse.x;
                                    mouseDragStart.y+=mouse.y;

                                    windowThumbnailitem.width=120
                                    windowThumbnailitem.height=80

                                    windowThumbnailitem.x+=mouse.x
                                    windowThumbnailitem.y+=mouse.y
                                //    pressDelayTimer.running=true
                                }

                                drag.target:windowThumbnailitem
                                drag.smoothed :true


                                drag.onActiveChanged: {
                                    if (!windowThumbnailitemMousearea.drag.active) {
                                        console.log('------- release on ' + windowThumbnailitemMousearea.drag.target + index)
                                        windowThumbnailitem.Drag.drop();

                                        if(!dropreceived){
                                            //恢复现场
                                            windowThumbnailitem.fillHeight=true
                                            windowThumbnailitem.fillWidth=true

                                        }
                                    }else{
                                        //console.log("mouse.x"+mouseDragStart.x+ " mouse.y:"+mouseDragStart.y +" win X: " +windowThumbnailitem.x+" win Y: "+windowThumbnailitem.y);
                                    }
                                }
                                states: State {
                                    when: windowThumbnailitemMousearea.drag.active;
                                    ParentChange {
                                        target: windowThumbnailitem;
                                        parent: root;
                                    }
                                    PropertyChanges {
                                        target: windowThumbnailitem;
                                        z: 100;
                                    }
                                    PropertyChanges{
                                        target:windowThumbnailitemMousearea
                                        width:120
                                        height:80
                                    }
                                    AnchorChanges{
                                        target: windowThumbnailitem;

                                        Layout.fillWidth: false
                                        Layout.fillHeight:false
                                    }
                                   
                                }
                            }
                            Rectangle {
                                id: closeClientBtn;
                                visible:false;
                                anchors.right: parent.right;
                                width: closeClientBtnIcon.width;
                                height: closeClientBtnIcon.height;
                                color: "transparent";
                                Image {
                                    id: closeClientBtnIcon;
                                    source: "qrc:///icons/data/close_normal.svg"
                                }
                                MouseArea {
                                    anchors.fill: closeClientBtn;
                                    onClicked: {
                                        qmlRemoveWindowThumbnail(currentScreen,$Model.currentIndex()+1, index, windowThumbnailitem.winId)
                                    }
                                }
                            }

                            states: State {
                                name: "isHightlighted"
                                when: isHightlighted
                                PropertyChanges {
                                    target: windowThumbnailitem
                                    scale: 1.2
                                }
                                PropertyChanges {
                                    target: backgroundrect
                                    border.width: 5;
                                }
                            }

                            Rectangle {
                                id: clientIcon;
                                x:windowThumbnailitem.width/2 -  clientIconImage.width/2;
                                y:windowThumbnailitem.height - clientIconImage.height;
                                width: clientIconImage.width;
                                height: clientIconImage.height;
                                color: "transparent";
                                Image {
                                    id: clientIconImage;
                                    source: "image://imageProvider/" + modelData ;
                                    cache : false
                                }
                            }
                        }
                    }
                Connections {
                    target: root
                    onResetModel: {
                        grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                        grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                        grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                        grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
                        windowThumbnail.model = $Model.windows(currentScreen, $Model.currentIndex()+1);

                        bigWindowThrumbContainer.curdesktop=$Model.currentIndex()+1
                    }
                }
                }
            }
        }
    }
    Component.onCompleted: {
        for (var i = 0; i < $Model.numScreens(); ++i) {
            var geom = $Model.screenGeometry(i);
            var src =
                'import QtQuick 2.0;' +
                'Loader {' +
                '	x: ' + geom.x + ';' +
                '	property int screenWidth: ' + geom.width + ';' +
                '   property int screenHeight: '+ geom.height + ';'+
                '	height: 260;' +
                '	property int currentScreen: ' + i + ';' +
                '	sourceComponent: desktopThumbmailView;' +
                '}';
            Qt.createQmlObject(src, root, "dynamicSnippet");
        }
    }
}
