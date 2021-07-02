/*
 *    Copyright 2014  Sebastian Kügler <sebas@kde.org>
 *    SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *    Copyright (C) 2021 by Mikel Johnson <mikel5764@gmail.com>
 *    Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License along
 *    with this program; if not, write to the Free Software Foundation, Inc.,
 *    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

import QtQuick 2.12
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons
// While using Kirigami in applets is normally a no, we
// use Avatar, which doesn't need to read the colour scheme
// at all to function, so there won't be any oddities with colours.
import org.kde.kirigami 2.13 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

PlasmaExtras.PlasmoidHeading {
    id: footer

    implicitHeight: Math.round(PlasmaCore.Units.gridUnit * 2.5)
    rightPadding: rightInset
    leftPadding: rightPadding
    property Item configureButton: configureButton
    property Item avatar: avatarButton
    background: Rectangle {
        color: Qt.lighter(theme.backgroundColor)
        opacity: .1
        border.width: 1
        border.color: "#cacbd0"
        radius: 5
    }


    KCoreAddons.KUser {
        id: kuser
    }
    anchors.bottomMargin: 30
    anchors.leftMargin: 0
    anchors.rightMargin: 0
    height: units.iconSizes.medium * 2

    PlasmaCore.DataSource {
        id: pmEngine
        engine: "powermanagement"
        connectedSources: ["PowerDevil", "Sleep States"]
        function performOperation(what) {
            var service = serviceForSource("PowerDevil")
            var operation = service.operationDescription(what)
            service.startOperationCall(operation)
        }
    }

    RowLayout {
        id: nameAndIcon
        anchors.leftMargin: units.largeSpacing * 3 - footer.rightPadding
        anchors.left: parent.left
        x: units.smallSpacing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        PlasmaComponents.RoundButton {
            id: avatarButton
            visible: KQuickAddons.KCMShell.authorize("kcm_users.desktop").length > 0

            flat: true

            Layout.preferredWidth: units.iconSizes.large * 0.8
            Layout.preferredHeight: Layout.preferredWidth

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

            Keys.onPressed: {
                // In search on backtab focus on search pane
                if (event.key == Qt.Key_Backtab && (root.state == "Search" || mainTabGroup.state == "top")) {
                    navigationMethod.state = "keyboard"
                    keyboardNavigation.state = "RightColumn"
                    root.currentContentView.forceActiveFocus()
                    event.accepted = true;
                    return;
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: PlasmaCore.Units.gridUnit
            Layout.alignment: Layout.AlignVCenter | Qt.AlignLeft

            PlasmaExtras.Heading {
                id: nameLabel
                anchors.fill: parent

                level: 4
                // font.weight: Font.Bold
                Text {
                    font.capitalization: Font.Capitalize
                }
                text: kuser.fullName
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    RowLayout {
        anchors.rightMargin: units.largeSpacing * 3 - footer.rightPadding
        anchors.right: parent.right
        x: -units.smallSpacing
        anchors.verticalCenter: parent.verticalCenter

        // looks visually balanced that way
        spacing: Math.round(PlasmaCore.Units.smallSpacing * 2.5)

        PlasmaComponents.TabButton {
            id: lockScreenButton
            // flat: true 
            NumberAnimation {
                id: animateLockOpacity
                target: lockScreenButton
                properties: "opacity"
                from: 1
                to: 0.5
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                id: animateLockOpacityReverse
                target: lockScreenButton
                properties: "opacity"
                from: 0.5
                to: 1
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.InOutQuad
            }
            icon.name: "system-lock-screen"
            onHoveredChanged: hovered ? animateLockOpacity.start() : animateLockOpacityReverse.start();
            enabled: pmEngine.data["Sleep States"]["LockScreen"]
            PlasmaComponents.ToolTip {
                text: i18nc("@action", "Lock Screen")
            }
            MouseArea {
                onClicked: pmEngine.performOperation("lockScreen")
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        PlasmaComponents.TabButton {
            id: leaveButton
            NumberAnimation {
                id: animateOpacity
                target: leaveButton
                properties: "opacity"
                from: 1
                to: 0.5
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                id: animateOpacityReverse
                target: leaveButton
                properties: "opacity"
                from: 0.5
                to: 1
                duration: PlasmaCore.Units.longDuration
                easing.type: Easing.InOutQuad
            }
            onHoveredChanged: hovered ? animateOpacity.start() : animateOpacityReverse.start();
            icon.name: "system-shutdown"
            PlasmaComponents.ToolTip {
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Leave ... ")
            }
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                onClicked: pmEngine.performOperation("requestShutDown")
                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
