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
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.components 2.0 as PlasmaComponents2

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
    property bool showAllApps: plasmoid.configuration.defaultAllApps
    property bool showRecents: false
    property int tileSide: 64 + 30
    onSearchingChanged: {
        if (!searching) {
            reset();
        } else {
            if (showRecents) resetPinned.start();
        }
    }
    signal  newTextQuery(string text)
    property real mainColumnHeight: tileSide * 3
    property real favoritesColumnHeight: (units.iconSizes.medium + units.smallSpacing * 2) * 4
    property var pinnedModel: plasmoid.configuration.favGridModel == 0 ? globalFavorites : plasmoid.configuration.favGridModel == 1 ? rootModel.modelForRow(0) : rootModel.modelForRow(1)
    property var recommendedModel: plasmoid.configuration.recentGridModel == 0 ? rootModel.modelForRow(1) : plasmoid.configuration.recentGridModel == 1 ? rootModel.modelForRow(0) : globalFavorites
    
    function reset() {
        if (showRecents) resetPinned.start();
        searchField.clear()
        searchField.focus = true
        showAllApps = plasmoid.configuration.defaultAllApps
        showRecents = false
        documentsFavoritesGrid.tryActivate(0, 0);
        allAppsGrid.tryActivate(0, 0);
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


    ParallelAnimation {
        id: removePinned
        running: false
        NumberAnimation { target: mainColumn; property: "height"; from: mainColumnHeight; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mainColumn; property: "opacity"; from: 1; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: documentsFavoritesGrid; property: "height"; from: favoritesColumnHeight; to: parent.height; duration: 500; easing.type: Easing.InOutQuad }
    }

    ParallelAnimation {
        id: restorePinned
        running: false
        NumberAnimation { target: mainColumn; property: "height"; from: 0; to: searching || showAllApps ? parent.height : mainColumnHeight; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: mainColumn; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: documentsFavoritesGrid; property: "height"; from: parent.height; to: favoritesColumnHeight; duration: 500; easing.type: Easing.InOutQuad }
    }

    ParallelAnimation {
        id: resetPinned
        running: false
        NumberAnimation { target: mainColumn; property: "height"; from: 0; to: searching || showAllApps ? parent.height : mainColumnHeight; duration: 0; }
        NumberAnimation { target: mainColumn; property: "opacity"; from: 0; to: 1; duration: 0; }
        NumberAnimation { target: documentsFavoritesGrid; property: "height"; from: parent.height; to: favoritesColumnHeight; duration: 0; }
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
            globalFavoritesGrid.model = pinnedModel
            documentsFavoritesGrid.model = recommendedModel
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

    PlasmaComponents2.Menu {
        id: contextMenu
        PlasmaComponents2.MenuItem {
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
        anchors.top: parent.top
        anchors.leftMargin: units.largeSpacing * 3
        anchors.left: parent.left
        x: units.smallSpacing
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        color: theme.textColor
        level: 5
        font.bold: true
        font.weight: Font.Bold
        text: i18n(showAllApps ? "All apps" : showRecents ? "Recommended" : "Pinned")
        visible: !searching
    }

    PlasmaComponents.Button  {
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (showAllApps || !showRecents)
                    showAllApps = !showAllApps
                else {
                    showRecents = !showRecents
                    if (showRecents)
                        removePinned.start();
                    else
                        restorePinned.start();
                }
            }
        }
        text: i18n(showAllApps || showRecents ? "Back" : "All apps")
        id: mainsecLabelGrid
        icon.name: showAllApps || showRecents ? "go-previous" : "go-next"
        font.pointSize: 9
        icon.height: 15
        icon.width: icon.height
        LayoutMirroring.enabled: true
        LayoutMirroring.childrenInherit: !showAllApps && !showRecents
        flat: false
        background: Rectangle {
            color: Qt.lighter(theme.backgroundColor)
            border.width: 1
            border.color: Qt.darker(theme.backgroundColor, 1.14)
            radius: 5
        }
        topPadding: 4
        bottomPadding: topPadding
        leftPadding: 8
        rightPadding: 8
        icon{
            width: height
            height: visible ? units.iconSizes.small : 0
            name: showAllApps || showRecents ? "go-previous" : "go-next"
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
            leftMargin: units.largeSpacing * 1.6
            rightMargin: units.largeSpacing
            topMargin: units.largeSpacing
            left: parent.left
            right: parent.right
            bottom: searching ? parent.bottom : showAllApps ? footer.top : undefined
            bottomMargin: showAllApps ? 5 : 0
        }
        height: searching || showAllApps || plasmoid.configuration.recentGridModel == 3 ? parent.height : mainColumnHeight
        property Item visibleGrid: globalFavoritesGrid
        function tryActivate(row, col) {
            if (visibleGrid) {
                visibleGrid.tryActivate(row, col);
            }
        }

        ItemGridView {
            id: globalFavoritesGrid
            model: pinnedModel
            width: parent.width
            height: plasmoid.configuration.recentGridModel == 3 ? parent.height : tileSide * 3
            cellWidth: tileSide
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
            showDescriptions: plasmoid.configuration.showDescription
            anchors {
                leftMargin: units.largeSpacing * 1.6;
            }
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
            showDescriptions: plasmoid.configuration.showDescription
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
        anchors.topMargin: units.largeSpacing * 0.5
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: units.largeSpacing * 3
        anchors.rightMargin: units.largeSpacing
        visible: plasmoid.configuration.recentGridModel != 3

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
            visible: !searching && !showAllApps && !showRecents
            text: i18n("Recommended")
        }

        PlasmaComponents.Button  {
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    showRecents = !showRecents
                    if (showRecents)
                        removePinned.start();
                    else
                        restorePinned.start();
                }
            }
            text: i18n(showRecents ? "Back" : "More")
            id: headsecLabelGrid
            icon.name: showRecents ? "go-previous" : "go-next"
            font.pointSize: 9
            icon.height: 15
            icon.width: icon.height
            LayoutMirroring.enabled: true
            LayoutMirroring.childrenInherit: !showRecents
            flat: false
            background: Rectangle {
                color: Qt.lighter(theme.backgroundColor)
                border.width: 1
                border.color: Qt.darker(theme.backgroundColor, 1.14)
                radius: 5
            }
            topPadding: 4
            bottomPadding: topPadding
            leftPadding: 8
            rightPadding: 8
            icon{
                width: height
                height: visible ? units.iconSizes.small : 0
                name: showRecents ? "go-previous" : "go-next"
            }

            anchors {
                verticalCenter: headLabelDocuments.verticalCenter
                rightMargin: units.largeSpacing * 6
                leftMargin: units.largeSpacing * 6
                left: parent.left
            }
            x: -units.smallSpacing
            visible: documentsFavoritesGrid.model.count > 6 && !searching && !showAllApps && !showRecents
        }

        ItemGridView {
            id: documentsFavoritesGrid
            visible: !searching && !showAllApps
            showDescriptions: true

            anchors{
                top: headLabelDocuments.bottom
                left: parent.left
                right: parent.right
                bottomMargin: 0
                topMargin: units.largeSpacing
            }

            increaseLeftSpacings: true
            height: showRecents ? parent.height : (units.iconSizes.medium + units.smallSpacing * 2) * 4
            cellWidth: parent.width * 0.4
            cellHeight: units.iconSizes.medium + units.smallSpacing * 5
            iconSize: units.iconSizes.medium
            model: recommendedModel
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

