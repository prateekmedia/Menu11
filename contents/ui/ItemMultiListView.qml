/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
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

import QtQuick 2.4

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import QtQuick.Controls 2.1
PlasmaExtras.ScrollArea {
    //
    id: itemMultiList

    anchors {
        top: parent.top
    }
    width: parent.width
    implicitHeight: itemColumn.implicitHeight //+ units.largeSpacing

    signal keyNavLeft(int subGridIndex)
    signal keyNavRight(int subGridIndex)
    signal keyNavUp()
    signal keyNavDown()

    property bool iconsEnabled: false
    property int itemHeight: Math.ceil((Math.max(theme.mSize(theme.defaultFont).height, units.iconSizes.small)
        + Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
        listItemSvg.margins.top + listItemSvg.margins.bottom)) / 2) * 2

    property alias model: repeater.model

    property alias count: repeater.count

    //clip: true
//    verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
//    horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOn

    flickableItem.flickableDirection: Flickable.VerticalFlick

    onFocusChanged: {
        if (!focus) {
            for (var i = 0; i < repeater.count; i++) {
                subListAt(i).focus = false;
            }
        }
    }

    function subListAt(index) {
        return repeater.itemAt(index).itemGrid;
    }

    function tryActivate(row, col) { // FIXME TODO: Cleanup messy algo.
        if (flickableItem.contentY > 0) {
            row = 0;
        }

        var target = null;
        var rows = 0;

        for (var i = 0; i < repeater.count; i++) {
            var grid = subListAt(i);

            if (rows <= row) {
                target = grid;
                rows += grid.count + 2; // Header counts as one.
            } else {
                break;
            }
        }

        if (target) {
            rows -= (target.count + 2);
            target.tryActivate(row - rows, col);
        }
    }

    Column {
        id: itemColumn

        width: itemMultiList.width - units.gridUnit

        Repeater {
            id: repeater

            delegate: Item {
                width: itemColumn.width
                height: headerHeight + listView.height + (index == repeater.count - 1 ? 0 : footerHeight)

                property int headerHeight: listViewLabel.height
                property int footerHeight: units.smallSpacing * 3
                visible:  listView.count > 0
                property Item itemGrid: listView

                PlasmaExtras.Heading {
                    id: listViewLabel
                    anchors.top: parent.top
                    //anchors.topMargin: 8
                    x: units.smallSpacing
                    width: parent.width - x
                    height: dummyHeading.height
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    opacity: 1.0
                    color: theme.textColor
                    level: 5
                    font.weight: Font.Bold
                    text: repeater.model.modelForRow(index).description
                }

                MouseArea {
                    width: parent.width
                    height: parent.height
                    onClicked: root.toggle()
                }

                ItemListView {
                    id: listView

                    anchors {
                        top: listViewLabel.bottom
                        topMargin: units.smallSpacing
                    }
                    width:  parent.width
                    itemHeight: itemMultiList.itemHeight
                    iconsEnabled: itemMultiList.iconsEnabled
                    model: repeater.model.modelForRow(index)

                    onFocusChanged: {
                        if (focus) {
                            itemMultiList.focus = true;
                        }
                    }

                    onCountChanged: {
                        if (itemMultiList.grabFocus && index == 0 && count > 0) {
                            currentIndex = 0;
                            focus = true;
                        }
                    }

                    onCurrentItemChanged: {
                        if (!currentItem) {
                            return;
                        }

                        if (index == 0 && currentIndex === 0) {
                            itemMultiList.flickableItem.contentY = 0;
                            return;
                        }

                        var y = currentItem.y;
                        y = contentItem.mapToItem(itemMultiList.flickableItem.contentItem, 0, y).y;

                        if (y < itemMultiList.flickableItem.contentY) {
                            itemMultiList.flickableItem.contentY = y;
                        } else {
                            y += itemHeight;
                            y -= itemMultiList.flickableItem.contentY;
                            y -= itemMultiList.viewport.height;

                            if (y > 0) {
                                itemMultiList.flickableItem.contentY += y;
                            }
                        }
                    }

                    onKeyNavUp: {
                        currentIndex = -1;
                        if (index > 0) {
                            var prevGrid = subListAt(index - 1);
                            prevGrid.tryActivate(prevGrid.count);
                        } else {
                            itemMultiList.keyNavUp();
                        }
                    }

                    onKeyNavDown: {
                        currentIndex = -1;
                        if (index < repeater.count - 1) {
                            subListAt(index + 1).tryActivate(0);
                        } else {
                            itemMultiList.keyNavDown();
                        }
                    }
                }

                // HACK: Steal wheel events from the nested grid view and forward them to
                // the ScrollView's internal WheelArea.
                Kicker.WheelInterceptor {
                    anchors.fill: listView
                    z: 1

                    destination: findWheelArea(itemMultiList.flickableItem)
                }
            }
        }
    }
}
