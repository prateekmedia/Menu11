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

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

FocusScope {
    id: root
    focus: true
    property int iconSize: mainColumnItem.iconSize
    property bool done: false

    function toggle(){
        plasmoid.expanded = false;
    }
    function mainReset(){
        mainColumnItem.reset()
    }
    Layout.minimumWidth:  mainColumnItem.width //+ tilesColumnItem.width
    Layout.maximumWidth:  mainColumnItem.width //+ tilesColumnItem.width
    Layout.minimumHeight: mainColumnItem.tileSide * 5 + 50
    Layout.maximumHeight: mainColumnItem.tileSide * 5 + 50
    
    signal appendSearchText(string text)

    Row{
        anchors.fill: parent
        spacing: units.largeSpacing

        MainColumnItem{
            id: mainColumnItem
            onNewTextQuery:  {
                appendSearchText(text)
            }
        }
    }


    Keys.onPressed: {
        if (event.key === Qt.Key_Escape) {
            plasmoid.expanded = false;
        }
    }

    function refreshModel() {
        mainColumnItem.reload()
        console.log("refresh model - menu Z")
    }

    Component.onCompleted: {
        rootModel.refreshed.connect(refreshModel)
        plasmoid.hideOnWindowDeactivate = true;
        kicker.reset.connect(mainReset);
        windowSystem.hidden.connect(mainReset);
    }
}
