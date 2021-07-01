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

    KCoreAddons.KUser {
        id: kuser
    }
    anchors.bottomMargin: 10
    height: units.iconSizes.medium * 2

    Rectangle{
        id: back
        anchors.fill: parent
        opacity: 0.2
        color: Qt.darker(theme.backgroundColor)
    }

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


Rectangle{
    id: divider
    visible: !searching
    anchors{
        left: parent.left
        right: parent.right
        top: lockScreenButton.top
        margins: units.largeSpacing
        bottomMargin: 0
    }
    color: theme.textColor
    height: 1
    opacity: 0.1
}

RowLayout {
    id: nameAndIcon
    anchors.leftMargin: units.largeSpacing * 1.2
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

            level: 5
            font.weight: Font.Bold
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
                    footer.state = "info"
                }
                onExited: {
                    footer.state = "name"
                }
            }
        }

        PlasmaExtras.Heading {
            id: infoLabel
            level: 6
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

RowLayout {
    anchors.rightMargin: units.largeSpacing * 1.2
    anchors.right: parent.right
    x: -units.smallSpacing
    anchors.verticalCenter: parent.verticalCenter

    // looks visually balanced that way
    spacing: Math.round(PlasmaCore.Units.smallSpacing * 2.5)

    PlasmaComponents.RoundButton {
        id: lockScreenButton
        icon.name: "system-lock-screen"
        enabled: pmEngine.data["Sleep States"]["LockScreen"]
        onClicked: pmEngine.performOperation("lockScreen")
        PlasmaComponents.ToolTip {
            text: i18nc("@action", "Lock Screen")
        }
    }

    PlasmaComponents.RoundButton {
        id: leaveButton
        icon.name: "system-shutdown"
        onClicked: pmEngine.performOperation("requestShutDown")
        PlasmaComponents.ToolTip {
            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Leave ... ")
        }
    }
}
}
