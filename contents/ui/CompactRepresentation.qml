/***************************************************************************
 *   Copyright (C) 2013-2014 by Eike Hein <hein@kde.org>                   *
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

import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore


import QtGraphicalEffects 1.0
import QtQuick.Controls.Styles 1.4
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

MouseArea{
    id: root

    readonly property bool inPanel: (plasmoid.location === PlasmaCore.Types.TopEdge
                                     || plasmoid.location === PlasmaCore.Types.RightEdge
                                     || plasmoid.location === PlasmaCore.Types.BottomEdge
                                     || plasmoid.location === PlasmaCore.Types.LeftEdge)
    readonly property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    readonly property bool useCustomButtonImage: (plasmoid.configuration.useCustomButtonImage
                                                  && plasmoid.configuration.customButtonImage.length !== 0)
    property QtObject dashWindow: null

    Layout.minimumWidth: {
        if (!inPanel) {  return units.iconSizeHints.panel;  }
        if (vertical) {
            return -1;
        } else {
            return plasmoid.configuration.widthPanel
        }
    }
    Layout.minimumHeight: {
        if (!inPanel) { return units.iconSizeHints.panel;  }
        if (vertical) {
            return Math.min(units.iconSizeHints.panel, parent.width) * buttonIcon.aspectRatio;
        } else {
            return -1;
        }
    }
    Layout.maximumWidth: {
        if (!inPanel) { return -1; }
        if (vertical) {
            return units.iconSizeHints.panel;
        } else {
            return  plasmoid.configuration.widthPanel
        }
    }

    Layout.maximumHeight: {
        if (!inPanel) { return -1; }
        if (vertical) {
            return Math.min(units.iconSizeHints.panel, parent.width) * buttonIcon.aspectRatio;
        } else {
            return units.iconSizeHints.panel;
        }
    }
    function colorWithAlpha(color, alpha) {

        if(!plasmoid.configuration.invertColors){
            return Qt.rgba(color.r, color.g, color.b, alpha)
        }else{
            return Qt.rgba(1 - color.r, 1 - color.g, 1- color.b, alpha)
        }
    }

    property int iconPanel: 22
    Rectangle{
        id: aRectArea
        anchors.fill:  boxSearch
        //color: Qt.lighter(Qt.lighter(colorWithAlpha(theme.backgroundColor,1)))
        color: colorWithAlpha(theme.backgroundColor,1)
        opacity: plasmoid.configuration.opacityBar/100
    }
    Rectangle{
        id: boxSearch
        //anchors.fill: parent
        width: parent.width - iconPanel - 8
        height: parent.height
        color: "transparent"
        border.width: plasmoid.configuration.showBorder ? 1 : (plasmoid.expanded ? 1 : 0)
        border.color: plasmoid.expanded ? theme.highlightColor : "#808080"

        PlasmaCore.IconItem {
            id: buttonIcon
            readonly property double aspectRatio: (vertical ? implicitHeight / implicitWidth
                                                            : implicitWidth / implicitHeight)

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            height: iconPanel
            width:  iconPanel
            source: Qt.resolvedUrl("images/search.svg")
            //active: parent.containsMouse  || compactDragArea.containsDrag
            smooth: true
            roundToIconSize: aspectRatio === 1
        }
        ColorOverlay {
            anchors.fill: buttonIcon
            source:       buttonIcon
            color:        colorWithAlpha(theme.textColor,1)
        }

        PlasmaComponents.TextField {
            id: panelSearch
            //anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: parent.width - buttonIcon.width
            anchors.left: buttonIcon.right
            verticalAlignment: Qt.AlignVCenter
            text: (root.textQuery === "") ? "" : root.textQuery + "_"
            focus: false
            textColor: colorWithAlpha(theme.textColor,1)
            placeholderText: "<font color='"+colorWithAlpha(theme.textColor,1)+"'>" + i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Type here to search") + "</font>"
            style: TextFieldStyle {
                background: Rectangle {
                    opacity: 1
                    color: "transparent"
                }
                font {
                    pointSize: 11
                }
            }

        }
        
        MouseArea{
            acceptedButtons: Qt.LeftButton
            anchors.fill: parent
            onClicked: {
                plasmoid.expanded = !plasmoid.expanded
            }
        }

    }
    PlasmaCore.IconItem {
        id: presentIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: boxSearch.right
        anchors.leftMargin: 8
        height: iconPanel
        width:  iconPanel
        source: Qt.resolvedUrl("images/tasks.svg")
        smooth: true
        MouseArea{
            acceptedButtons: Qt.LeftButton
            anchors.fill: parent
            onClicked: {
                exposeDesktop()
            }
        }

    }
    ColorOverlay {
        anchors.fill: presentIcon
        source:       presentIcon
        color:        theme.textColor
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }
    function exposeDesktop() {
        executable.exec('qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Expose"')
    }
}
