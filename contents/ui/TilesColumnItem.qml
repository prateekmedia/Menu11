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


//import "../code/tools.js" as Tools
import "code/tools.js" as Tools

Item {
    id: item

    width:  tileSide * 3.5
    height: root.height

    property int tileSide: 64 + 30
    property int iconSize: units.iconSizes.large
    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
                           + (2 * units.smallSpacing)
                           + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                           highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    //property int columns: Math.floor(((smallScreen ? 85 : 80)/100) * Math.ceil(width / cellSize))
    //    onKeyEscapePressed: {
    //    }

    onVisibleChanged: {
    }

    MouseArea {
        id: rootItem

        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Connections {
            target: kicker

            onReset: {

            }

            onDragSourceChanged: {
                if (!dragSource) {
                    // FIXME TODO HACK: Reset all views post-DND to work around
                    // mouse grab bug despite QQuickWindow::mouseGrabberItem==0x0.
                    // Needs a more involved hunt through Qt Quick sources later since
                    // it's not happening with near-identical code in the menu repr.
                    rootModel.refresh();
                }
            }
        }

        KWindowSystem {
            id: kwindowsystem
        }


        PlasmaComponents.Menu {
            id: contextMenu

            PlasmaComponents.MenuItem {
                action: plasmoid.action("configure")
            }
        }

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


        Column {
            id: middleRow

            width: parent.width
            height: parent.height
            spacing: units.smallSpacing

            PlasmaExtras.Heading {
                id: favoritesColumnLabel

                x: units.smallSpacing
                width: parent.width - x

                elide: Text.ElideRight
                wrapMode: Text.NoWrap

                color: theme.textColor

                level: 3

                text: i18n("Favorites")

                opacity: (enabled ? 1.0 : 0.3)

                Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }
            }


            ItemGridView {
                id: globalFavoritesGrid

                property int rows: 2

                width:  parent.width
                height: rows * tileSide

                cellWidth:  tileSide// cellSize
                cellHeight: tileSide// cellSize
                iconSize:   root.iconSize
                square: true

                model: globalFavorites

                dropEnabled: true
                usesPlasmaTheme: false

                opacity: (enabled ? 1.0 : 0.3)

                Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

                onCurrentIndexChanged: {
                    //                        preloadAllAppsTimer.defer();
                }

                onKeyNavRight: {
                    //                        mainColumn.tryActivate(currentRow(), 0);
                }

                onKeyNavDown: {
                    // systemFavoritesGrid.tryActivate(0, currentCol());
                }

                Keys.onPressed: {
                    //   if (event.key == Qt.Key_Tab) {
                    //       event.accepted = true;
                    //
                    //       if (tabBar.visible) {
                    //           tabBar.focus = true;
                    //       } else if (searching) {
                    //           cancelSearchButton.focus = true;
                    //       } else {
                    //           mainColumn.tryActivate(0, 0);
                    //       }
                    //   } else if (event.key == Qt.Key_Backtab) {
                    //       event.accepted = true;
                    //       systemFavoritesGrid.tryActivate(0, 0);
                    //   }
                }

                Binding {
                    target: globalFavorites
                    property: "iconSize"
                    value: root.iconSize
                }
            }

            PlasmaExtras.Heading {
                x: units.smallSpacing
                width: parent.width - x

                elide: Text.ElideRight
                wrapMode: Text.NoWrap

                color: theme.textColor

                level: 3

                text: i18n("Recent")

                opacity: (enabled ? 1.0 : 0.3)

                Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }
            }


            ItemGridView {
                id: documentsFavoritesGrid



                property int rows: 3

                width:  parent.width
                height: rows * tileSide

                cellWidth:   tileSide
                cellHeight:  tileSide
                iconSize:  iconSize
                square: true

                model: rootModel.modelForRow(1);

                dropEnabled: true
                usesPlasmaTheme: false

                opacity: (enabled ? 1.0 : 0.3)

                Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

                onCurrentIndexChanged: {
                    //                        preloadAllAppsTimer.defer();
                }

                onKeyNavRight: {
                    //                        mainColumn.tryActivate(currentRow(), 0);
                }

                onKeyNavDown: {
                    // systemFavoritesGrid.tryActivate(0, currentCol());
                }

                Keys.onPressed: {
                    //   if (event.key == Qt.Key_Tab) {
                    //       event.accepted = true;
                    //
                    //       if (tabBar.visible) {
                    //           tabBar.focus = true;
                    //       } else if (searching) {
                    //           cancelSearchButton.focus = true;
                    //       } else {
                    //           mainColumn.tryActivate(0, 0);
                    //       }
                    //   } else if (event.key == Qt.Key_Backtab) {
                    //       event.accepted = true;
                    //       systemFavoritesGrid.tryActivate(0, 0);
                    //   }
                }

                //Binding {
                //    target: globalFavorites
                //    property: "iconSize"
                //    value: root.iconSize
                //}
            }
        }


        onPressed: {
            if (mouse.button == Qt.RightButton) {
                contextMenu.open(mouse.x, mouse.y);
            }
        }

        onClicked: {
            if (mouse.button == Qt.LeftButton) {
                root.toggle();
            }
        }
    }

}

