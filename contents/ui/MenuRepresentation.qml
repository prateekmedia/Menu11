/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
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

import QtQuick 2.12
import QtQuick.Layouts 1.12
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0

import org.kde.kwindowsystem 1.0
import QtGraphicalEffects 1.0
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.quicklaunch 1.0


import QtQuick.Dialogs 1.2
PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int iconSize: units.iconSizes.medium
    property int iconSizeSide: units.iconSizes.smallMedium
    property int cellWidth: units.gridUnit * 13
    property int cellWidthSide: units.gridUnit * 13
    property int cellHeight: iconSize + (Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
        highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    signal appendSearchText(string text)

    onVisibleChanged: {
        if (!visible) {
            reset();
        } else {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
        }
    }

    onHeightChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onWidthChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    function toggle() {
        root.visible = false;
    }

    function reset() {
        mainColumnItem.reset()
    }

    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;
        //QtBug - QTBUG-64115
        var screen = Qt.rect(screenAvail.x + screenGeom.x,
            screenAvail.y + screenGeom.y,
            screenAvail.width,
            screenAvail.height);

        var offset = units.smallSpacing;

        // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
        var x = offset;
        var y = screen.height - height - offset;
        var horizMidPoint; z
        var vertMidPoint;
        var appletTopLeft;
        if (plasmoid.configuration.centerMenu) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            //y = vertMidPoint - height / 2;
            y = plasmoid.location === PlasmaCore.Types.TopEdge ? parent.height + panelSvg.margins.bottom + offset + 6 :  screen.height - height - offset - panelSvg.margins.top - 6;
        } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset + 6 : (screen.x + screen.width) - width - offset - 6;
            y = screen.height - height - offset - panelSvg.margins.top - 6;
        } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset + 6 : (screen.x + screen.width) - width - offset - 6;
            y = parent.height + panelSvg.margins.bottom + offset + 6;
        } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = parent.width + panelSvg.margins.right + offset + 6;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset + 6 : (screen.y + screen.height) - height - offset - 6;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width - 6;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset + 6 : (screen.y + screen.height) - height - offset - 6;
        }

        return Qt.point(x, y);
    }


    FocusScope {
        Layout.minimumWidth: mainColumnItem.width  //+ tilesColumnItem.width
        Layout.maximumWidth: mainColumnItem.width //+ tilesColumnItem.width
        Layout.minimumHeight: mainColumnItem.tileSide * 6 + 85
        Layout.maximumHeight: mainColumnItem.tileSide * 6 + 85

        focus: true

        Row{
            anchors.fill: parent
            spacing: units.largeSpacing

            MainColumnItem{
                id: mainColumnItem
                onNewTextQuery: {
                    appendSearchText(text)
                }
            }
        }


        Keys.onPressed: {
            if (event.key == Qt.Key_Escape) {
                root.visible = false;
            }
        }
    }

    Component.onCompleted: {
        kicker.reset.connect(reset);
        reset();
    }
}
