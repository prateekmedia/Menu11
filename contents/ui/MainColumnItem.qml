/***************************************************************************
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>           *
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
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0
//import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import org.kde.kirigami 2.13 as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kwindowsystem 1.0
import org.kde.plasma.private.shell 2.0
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

import "../code/tools.js" as Tools

Item {
    id: item

    width: tileSide * 6 + 16 * units.smallSpacing
    height: root.height
    y: units.largeSpacing * 2
    property int iconSize: units.iconSizes.large
    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
        + (2 * units.smallSpacing)
        + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
            highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property bool searching: (searchField.text != "")
    property bool showAllApps: false
    property int tileSide: 64 + 30
    onSearchingChanged: {
        if (!searching) {
            reset();
        }
    }
    signal  newTextQuery(string text)

    function reset() {
        mainColumn.visibleGrid = globalFavoritesGrid
        searchField.clear()
        searchField.focus = true
        showAllApps = false
        globalFavoritesGrid.tryActivate(0, 0);
    }

    function reload() {
        mainColumn.visible = false
        recentItem.visible = false
        globalFavoritesGrid.model = null
        documentsFavoritesGrid.model = null
        allAppsGrid.model = null
        preloadAllAppsTime.done = false
        preloadAllAppsTime.defer()
    }

    KWindowSystem {
        id: kwindowsystem
    }
    KCoreAddons.KUser { id: kuser }

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
            globalFavoritesGrid.model = globalFavorites
            documentsFavoritesGrid.model = rootModel.modelForRow(1);
            allAppsGrid.model = rootModel.modelForRow(2);
            done = true;
            mainColumn.visible = true
            recentItem.visible = true
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
        focus: true
        placeholderText: i18n("Search...")
        opacity: searching
        height: units.iconSizes.medium
        width: parent.width - 2 * x
        x: 1.5 * units.largeSpacing
        Accessible.editable: true
        Accessible.searchEdit: true
        onTextChanged: {
            runnerModel.query = text;
            newTextQuery(text)
        }
        function clear() {
            text = "";
        }
        function backspace() {
            if (searching) {
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
            if (event.key == Qt.Key_Down) {
                event.accepted = true;
                mainColumn.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Up) {
                event.accepted = true;
                mainColumn.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if (searching) {
                    clear()
                } else {
                    root.toggle()
                }
            }
        }
    }

    PlasmaExtras.Heading {
        id: mainLabelGrid
        anchors.top: parent.top + 10//headRect.bottom
        anchors.leftMargin: units.largeSpacing * 3
        anchors.left: parent.left
        x: units.smallSpacing
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        color: theme.textColor
        level: 5
        font.bold: true
        font.weight: Font.Bold
        text: i18n(showAllApps ? "All apps" : "Pinned")
        visible: !searching
    }

    PlasmaComponents.Button  {
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: showAllApps = !showAllApps
        }
        text: i18n(showAllApps ? "Back" : "All apps")
        id: mainsecLabelGrid
        icon.name: showAllApps ? "go-previous" : "go-next"
        font.pointSize: 9
        icon.height: 15
        icon.width: icon.height
        LayoutMirroring.enabled: true
        LayoutMirroring.childrenInherit: !showAllApps
        flat: false        
        background: Rectangle {
            color: Qt.lighter(theme.backgroundColor)
            border.width: 1
            border.color: Qt.darker(theme.backgroundColor, 1.14)
            radius: 5
        }
        topPadding: 5
        bottomPadding: topPadding
        leftPadding: 8
        rightPadding: 8
        icon{
            width: height
            height: visible ? units.iconSizes.small : 0
            name: showAllApps ? "go-previous" : "go-next"
        }

        anchors {
            verticalCenter: mainLabelGrid.verticalCenter
            rightMargin: units.largeSpacing * 3
            leftMargin: units.largeSpacing * 3
            left: parent.left
        }
        x: -units.smallSpacing
        visible: !searching
    }

    Item {
        id: mainColumn
        anchors {
            top: searching ? searchField.bottom : mainLabelGrid.bottom
            leftMargin:  units.largeSpacing * (searching ? 1.6 : 3)
            rightMargin: anchors.leftMargin
            topMargin: units.largeSpacing * 0.8
            left: parent.left
            right: parent.right
            bottom: searching ? parent.bottom : showAllApps ? footer.top : undefined
            bottomMargin: showAllApps ? 5 : 0
        }
        height: searching || showAllApps ? parent.height : tileSide * 3
        property Item visibleGrid: globalFavoritesGrid
        function tryActivate(row, col) {
            if (visibleGrid) {
                visibleGrid.tryActivate(row, col);
            }
        }

        ItemGridView {
            id: globalFavoritesGrid
            model: globalFavorites
            width: parent.width
            height: tileSide * 3
            cellWidth: tileSide * 0.92
            cellHeight: tileSide
            square: true
            dropEnabled: true
            usesPlasmaTheme: true
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            opacity: searching || showAllApps ? 0 : 1
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = globalFavoritesGrid;
                }
            }
            onKeyNavDown: documentsFavoritesGrid.tryActivate(0, 0)

        }

        ItemMultiGridView {
            id: allAppsGrid
            anchors.fill: parent
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            height: parent.height
            width: parent.width
            model: rootModel.modelForRow(2)
            opacity: showAllApps && !searching ? 1.0 : 0.0
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = allAppsGrid;
                }
            }
        }

        ItemMultiGridView {
            id: runnerGrid
            anchors.fill: parent
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            width: parent.width
            model: runnerModel
            opacity: searching ? 1.0 : 0.0
            onOpacityChanged: {
                if (opacity == 1.0) {
                    mainColumn.visibleGrid = runnerGrid;
                }
            }
        }

        Keys.onPressed: {

            if (event.key == Qt.Key_Tab) {
                event.accepted = true;
                documentsFavoritesGrid.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                if (searching)
                    searchField.backspace();
                else
                    searchField.focus = true
            } else if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if (searching) {
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
        width: parent.width
        anchors.top: mainColumn.bottom
        anchors.topMargin: units.largeSpacing * 0.8
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: units.largeSpacing * 3
        anchors.rightMargin: anchors.leftMargin

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
            visible: !searching && !showAllApps
            text: i18n("Recommended")
        }

        ItemGridView {
            id: documentsFavoritesGrid
            visible: !searching && !showAllApps
            showDescriptions: true

            anchors{
                top: headLabelDocuments.bottom
                left: parent.left
                right: parent.right
                bottom: footer.top
                // topMargin: parent.margins.top
                bottomMargin: 0
                topMargin: units.largeSpacing * 0.8
            }

            increaseLeftSpacings: true

            height: (units.iconSizes.medium + units.smallSpacing * 2) * 4
            cellWidth: parent.width * 0.4
            cellHeight: units.iconSizes.medium + units.smallSpacing * 5
            iconSize: units.iconSizes.medium
            model: rootModel.modelForRow(1);
            usesPlasmaTheme: false

            onKeyNavUp: {
                mainColumn.visibleGrid.tryActivate(0, 0);
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    mainColumn.visibleGrid.tryActivate(0, 0)
                } else if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    if (searching)
                        searchField.backspace();
                    else
                        searchField.focus = true
                } else if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if (searching) {
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

    Footer {
        id: footer
        visible: !searching
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Component.onCompleted: {
        searchField.focus = true
    }
}

