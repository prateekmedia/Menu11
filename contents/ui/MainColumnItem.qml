/***************************************************************************
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/


import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0

//
//import QtQuick 2.0
import QtQuick 2.4
import QtGraphicalEffects 1.0
//import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kwindowsystem 1.0
import org.kde.plasma.private.shell 2.0
import org.kde.plasma.private.kicker 0.1 as Kicker
import QtQuick.Layouts 1.0
import org.kde.kcoreaddons 1.0 as KCoreAddons

import "code/tools.js" as Tools

Item {
    id: item

    width:  tileSide * 6 + 3 * units.largeSpacing
    height: root.height
    property int iconSize: units.iconSizes.large
    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
                           + (2 * units.smallSpacing)
                           + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                           highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property bool searching: (searchField.text != "")
    property int tileSide: 64 + 30
    onSearchingChanged: {
        if (!searching) {
            reset();
        }
    }
    signal  newTextQuery(string text)
    Connections {
        target: plasmoid
        onExpandedChanged: {
            if (expanded) {
                playAllGrid.start()
            }
        }
    }
    SequentialAnimation {
        id: playAllGrid
        running: false
        NumberAnimation { target: allAppsGrid ; property: "x"; from: 100; to: 0; duration: 500; easing.type: Easing.InOutQuad}
    }

    function reset() {
        mainColumn.visibleGrid = allAppsGrid
        searchField.clear();
        searchField.focus = true
        allAppsGrid.tryActivate(0,0);
    }

    function reload(){
        mainColumn.visible = false
        recentItem.visible = false
        allAppsGrid.model = null
        documentsFavoritesGrid.model = null
        preloadAllAppsTime.done = false
        preloadAllAppsTime.defer()
    }

    KWindowSystem {
        id: kwindowsystem
    }
    KCoreAddons.KUser {   id: kuser  }

    PlasmaExtras.Heading {
        id: dummyHeading

        visible: false
        width: 0
        level: 1
    }

    TextMetrics {
        id: headingMetrics
        font: dummyHeading.font
    }

    Timer {
        id: preloadAllAppsTime
        property bool done: false
        interval: 1000
        repeat: false
        onTriggered: {
            if (done) {
                return;
            }
            allAppsGrid.model = rootModel.modelForRow(0)
            documentsFavoritesGrid.model = rootModel.modelForRow(1);
            done = true;
            mainColumn.visible =  true
            recentItem.visible = true
            playAllGrid.start()
        }
        function defer() {
            if (!running && !done) {
                restart();
            }
        }
    }

    Kicker.ContainmentInterface {
        id: containmentInterface
    }

    PlasmaComponents.Menu {
        id: contextMenu
        PlasmaComponents.MenuItem {
            action: plasmoid.action("configure")
        }
    }


    PlasmaComponents.TextField {
        id: searchField
        anchors.top: parent.top
        focus: true
        height: units.iconSizes.medium
        width:  parent.width
        visible: false
        onTextChanged: {
            runnerModel.query = text;
            newTextQuery(text)
        }
        function clear() {
            text = "";
        }
        function backspace() {
            if(searching){
                text = text.slice(0, -1);
            }
            focus = true;
        }
        function appendText(newText) {
            if (!root.visible) {
                return;
            }
            focus = true;
            text = text + newText;
        }
        Keys.onPressed: {
            if (event.key == Qt.Key_Space) {
                event.accepted = true;
            } else if (event.key == Qt.Key_Down) {
                event.accepted = true;
                mainColumn.tryActivate(0,0)
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Up) {
                event.accepted = true;
                mainColumn.tryActivate(0,0)
            } else if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                if(searching)
                    searchField.backspace();
                else
                    searchField.focus = true
            } else if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if(searching){
                    clear()
                } else {
                    root.toggle()
                }
            }
        }
    }

    PlasmaExtras.Heading {
        id: mainLabelGrid
        anchors.top: parent.top//headRect.bottom
        anchors.leftMargin: units.largeSpacing
        anchors.left: parent.left
        x: units.smallSpacing
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        color: theme.textColor
        level: 5
        font.bold: true
        font.weight: Font.Bold
        text: i18n("Top Apps")
        visible: !searching
    }

    Item {
        id: mainColumn
        anchors.top: searching ? parent.top : mainLabelGrid.bottom
        anchors.margins: units.largeSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        height: searching ?  parent.height :  tileSide * 2
        property Item visibleGrid: allAppsGrid
        function tryActivate(row, col) {
            if (visibleGrid) {
                visibleGrid.tryActivate(row, col);
            }
        }

        ItemGridView {
            id: allAppsGrid
            width:  parent.width
            height: searching ?  parent.height :  tileSide * 2
            cellWidth:   tileSide
            cellHeight:  tileSide
            iconSize:  iconSize
            square: true
            model: rootModel.modelForRow(0);
            dropEnabled: true
            usesPlasmaTheme: false
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            opacity: searching ? 0 : 1
            onOpacityChanged: {
                if (opacity == 1.0) {
                    //allAppsGrid.flickableItem.contentY = 0;
                    mainColumn.visibleGrid = allAppsGrid;
                }
            }
            onKeyNavDown: documentsFavoritesGrid.tryActivate(0,0)

        }

        ItemMultiGridView {
            id: runnerGrid
            anchors.fill: parent
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            model: runnerModel
            tileSide: tileSide
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            grabFocus: true
            square: true
            opacity: searching ? 1.0 : 0.0
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = runnerGrid;
                }
            }
            onKeyNavDown: {

               if(!searching)
                    documentsFavoritesGrid.tryActivate(0,0)

            }
        }

        Keys.onPressed: {
            
            if (event.key == Qt.Key_Tab) {
                event.accepted = true;
                documentsFavoritesGrid.tryActivate(0,0)
            } else if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                if(searching)
                    searchField.backspace();
                else
                    searchField.focus = true
            } else if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if(searching){
                    searchField.clear()
                } else {
                    root.toggle()
                }
            } else if (event.text != "") {
                event.accepted = true;
                searchField.appendText(event.text);
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            onPressed: {
                if (mouse.button == Qt.RightButton) {
                    contextMenu.open(mouse.x, mouse.y);
                }
            }

            onClicked: {
                if (mouse.button == Qt.LeftButton) {
                }
            }
        }

    }

    Item{

        id: recentItem
        width: parent.width * 0.65

        //anchors.top:    searching ? undefined : mainColumn.bottom
        anchors.top:   mainColumn.bottom
        anchors.topMargin: units.largeSpacing
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: units.largeSpacing

        visible: !searching

        property int iconSize: 22

        PlasmaExtras.Heading {
            id: headLabelDocuments
            x: units.smallSpacing
            width: parent.width - x
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            color: theme.textColor
            level: 5
            font.bold: true
            font.weight: Font.Bold
            text: i18n("Recent")
        }

        ItemGridView {
            id: documentsFavoritesGrid
            property int rows: 3
            anchors.top: headLabelDocuments.bottom
            anchors.topMargin: units.largeSpacing
            anchors.leftMargin: units.largeSpacing
            width:  parent.width //parent.width * 0.7
            height: tileSide * 2 + units.largeSpacing
            cellWidth:   tileSide * 2
            cellHeight:  24
            iconSize:    units.iconSizes.smallMedium
            model: rootModel.modelForRow(1);
            dropEnabled: true
            usesPlasmaTheme: false
            onKeyNavLeft: {
                //mainColumn.visibleGrid.tryActivate(0,0);
            }

            onKeyNavUp: {
                mainColumn.visibleGrid.tryActivate(0,0);
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    mainColumn.visibleGrid.tryActivate(0,0)
                }  else if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    if(searching)
                        searchField.backspace();
                    else
                        searchField.focus = true
                } else if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if(searching){
                        searchField.clear()
                    } else {
                        root.toggle()
                    }
                } else if (event.text != "") {
                    event.accepted = true;
                    searchField.appendText(event.text);
                }

            }
        }
    }

    Item{


        anchors.top:    searching ? undefined : mainColumn.bottom
        anchors.left: recentItem.right
        anchors.right: parent.right
        width: parent.width * 0.25
        anchors.bottom: parent.bottom
        anchors.margins: units.largeSpacing
        visible: !searching
        Clock{
            anchors.fill: parent
        }

    }

    Component.onCompleted: {
        searchField.focus = true
    }
}

