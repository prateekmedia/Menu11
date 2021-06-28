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
//import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.13 as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kwindowsystem 1.0
import org.kde.plasma.private.shell 2.0
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

import "code/tools.js" as Tools

Item {
    id: item

    width: tileSide * 6 + 3 * units.largeSpacing
    height: root.height
    y: 10
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
        NumberAnimation { target: globalFavoritesGrid; property: "x"; from: 100; to: 0; duration: 500; easing.type: Easing.InOutQuad }
    }

    function reset() {
        mainColumn.visibleGrid = globalFavoritesGrid
        searchField.clear();
        searchField.focus = true
        globalFavoritesGrid.tryActivate(0, 0);
    }

    function reload() {
        mainColumn.visible = false
        recentItem.visible = false
        bottomItem.visible = false
        globalFavoritesGrid.model = null
        documentsFavoritesGrid.model = null
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
            done = true;
            mainColumn.visible = true
            recentItem.visible = true
            bottomItem.visible = true
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
        focus: true
        opacity: searching
        height: units.iconSizes.medium
        width: parent.width - x
        x: units.smallSpacing
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
            if (event.key == Qt.Key_Space) {
                event.accepted = true;
            } else if (event.key == Qt.Key_Down) {
                event.accepted = true;
                mainColumn.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Up) {
                event.accepted = true;
                mainColumn.tryActivate(0, 0)
            } else if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                if (searching)
                    searchField.backspace();
                else
                    searchField.focus = true
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
        text: i18n("Pinned")
        visible: !searching && !showAllApps
    }

    PlasmaComponents.ToolButton  {
        text: showAllApps ? "Pinned" : "All Apps"
        id: mainsecLabelGrid
        anchors.top: parent.top//headRect.bottom
        anchors.rightMargin: units.largeSpacing
        anchors.right: parent.right
        x: -units.smallSpacing
        font.bold: true
        font.weight: Font.Bold
        visible: !searching
        onClicked: showAllApps = !showAllApps
    }

    Item {
        id: mainColumn
        anchors.top: searching ? searchField.bottom : mainLabelGrid.bottom
        anchors.margins: units.largeSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        height: searching ? parent.height : tileSide * 2
        property Item visibleGrid: globalFavoritesGrid
        function tryActivate(row, col) {
            if (visibleGrid) {
                visibleGrid.tryActivate(row, col);
            }
        }

        ItemGridView {
            id: globalFavoritesGrid
            width: parent.width
            height: searching ? parent.height : tileSide * 2
            cellWidth: tileSide
            cellHeight: tileSide
            iconSize: iconSize
            square: true
            model: globalFavorites
            dropEnabled: true
            usesPlasmaTheme: false
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            z: (opacity == 1.0) ? 1 : 0
            enabled: (opacity == 1.0) ? 1 : 0
            opacity: searching || showAllApps ? 0 : 1
            onOpacityChanged: {
                if (opacity == 1.0) {
                    //globalFavoritesGrid.flickableItem.contentY = 0;
                    mainColumn.visibleGrid = globalFavoritesGrid;
                }
            }
            onKeyNavDown: documentsFavoritesGrid.tryActivate(0, 0)

        }

        ItemGridView {
            id: allAppsGrid
            anchors.fill: parent
            z: (opacity == 1.0) ? 1 : 0
            width:  parent.width
            height: parent.height
            enabled: (opacity == 1.0) ? 1 : 0
            cellWidth: tileSide
            cellHeight: tileSide
            iconSize: iconSize
            square: true
            usesPlasmaTheme: false
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            opacity: !searching && showAllApps ? 1 : 0
            model: rootModel.modelForRow(2);
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

        //anchors.top:    searching ? undefined : mainColumn.bottom
        anchors.top: mainColumn.bottom
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
            width: parent.width //parent.width * 0.7
            height: tileSide * 2 + units.largeSpacing
            cellWidth: tileSide * 2
            cellHeight: 24
            iconSize: units.iconSizes.smallMedium
            model: rootModel.modelForRow(1);
            dropEnabled: true
            usesPlasmaTheme: false
            onKeyNavLeft: {
                //mainColumn.visibleGrid.tryActivate(0,0);
            }

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

    Item {
        id: bottomItem
        width: parent.width

        //anchors.top:    searching ? undefined : recentItem.bottom
        anchors.top: documentsFavoritesGrid.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: units.largeSpacing
        visible: !searching
        property int iconSize: 22

        PlasmaExtras.PlasmoidHeading {
            id: header
            x: units.smallSpacing
            y: -50
            implicitHeight: Math.round(PlasmaCore.Units.gridUnit * 2.5)
            rightPadding: rightInset

            property Item configureButton: configureButton
            property Item avatar: avatarButton

            state: "name"

            states: [
                State {
                    name: "name"
                    PropertyChanges {
                    target: nameLabel
                        opacity: 1
                }
                    PropertyChanges {
                    target: infoLabel
                        opacity: 0
                }
                },
        State {
            name: "info"
            PropertyChanges {
                target: nameLabel
                opacity: 0
            }
            PropertyChanges {
                target: infoLabel
                opacity: 1
            }
        }
            ] // states
        RowLayout {
            id: nameAndIcon
            width:parent.width
            anchors {
                left: parent.left
                leftMargin: PlasmaCore.Units.gridUnit + header.leftInset + PlasmaCore.Units.devicePixelRatio //border width
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Math.round(parent.width / 1.5) + PlasmaCore.Units.gridUnit
            }
            PlasmaComponents.RoundButton {
                id: avatarButton
                visible: KQuickAddons.KCMShell.authorize("kcm_users.desktop").length > 0
                y: -50

                flat: true

                Layout.preferredWidth: PlasmaCore.Units.gridUnit * 2
                Layout.preferredHeight: PlasmaCore.Units.gridUnit * 2

                Accessible.name: nameLabel.text
                Accessible.description: i18n("Go to user settings")

                Kirigami.Avatar {
                    source: kuser.faceIconUrl
                    name: nameLabel.text
                    anchors {
                        fill: parent
                        margins: PlasmaCore.Units.smallSpacing
                    }
                    // NOTE: for some reason Avatar eats touch events even though it shouldn't
                    // Ideally we'd be using Avatar but it doesn't have proper key nav yet
                    // see https://invent.kde.org/frameworks/kirigami/-/merge_requests/218
                    actions.main: Kirigami.Action {
                        text: avatarButton.Accessible.description
                        onTriggered: avatarButton.clicked()
                    }
                    // no keyboard nav
                    activeFocusOnTab: false
                    // ignore accessibility (done by the button)
                    Accessible.ignored: true
                }

                onClicked: {
                    KQuickAddons.KCMShell.openSystemSettings("kcm_users")
                }

                // Keys.onPressed: {
                //     // In search on backtab focus on search pane
                //     if (event.key == Qt.Key_Backtab && (root.state == "Search" || mainTabGroup.state == "top")) {
                //         navigationMethod.state = "keyboard"
                //         keyboardNavigation.state = "RightColumn"
                //         root.currentContentView.forceActiveFocus()
                //         event.accepted = true;
                //         return;
                //     }
                // }
            }

            Item {
                Layout.preferredHeight: PlasmaCore.Units.gridUnit
                Layout.alignment: Layout.AlignVCenter | Qt.AlignLeft

                PlasmaExtras.Heading {
                    id: nameLabel

                    level: 2
                    text: kuser.fullName
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    Behavior on opacity {
                        NumberAnimation {
                            duration: PlasmaCore.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Show the info instead of the user's name when hovering over it
                    MouseArea {
                        anchors.fill: nameLabel
                        hoverEnabled: true
                        onEntered: {
                            header.state = "info"
                        }
                        onExited: {
                            header.state = "name"
                        }
                    }
                }

                PlasmaExtras.Heading {
                    id: infoLabel
                    level: 5
                    opacity: 0
                    text: kuser.os !== "" ? i18n("%2@%3 (%1)", kuser.os, kuser.loginName, kuser.host) : i18n("%1@%2", kuser.loginName, kuser.host)
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    Behavior on opacity {
                        NumberAnimation {
                            duration: PlasmaCore.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }


            }
        }
    }
}

Component.onCompleted: {
    searchField.focus = true
}
}

