/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import LunaNext.Common 0.1
import LunaNext.Shell 0.1
import LunaNext.Compositor 0.1

import "CardView"
import "StatusBar"
import "LaunchBar"
import "WindowManager"
import "LunaSysAPI"
import "Utils"
import "Alerts"
import "Connectors"

Rectangle {
    id: root

    color: "black"

    Loader {
        anchors.top: root.top
        anchors.left: root.left

        width: 50
        height: 32

        // always on top of everything else!
        z: 1000

        Component {
            id: fpsTextComponent
            Text {
                color: "red"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                text: fpsCounter.fps + " fps"

                FpsCounter {
                    id: fpsCounter
                }
            }
        }

        sourceComponent: Settings.displayFps ? fpsTextComponent : null;
    }

    Preferences {
        id: preferences
    }

    Loader {
        id: reticleArea
        anchors.fill: parent
        source: Settings.showReticle ? "Utils/ReticleArea.qml" : ""
        z: 1000
    }

    PowerMenu {
        id: powerMenuAlert
        z: 800

        anchors.top: parent.bottom
        anchors.margins: 20

        width: parent.width * 0.6
    }

    VolumeControlAlert {
        id: volumeControlAlert
        z: 900
    }

    VisualItemModel {
        id: pageModel

        SystemMenuPage {
            id: systemMenuPage

            height: root.height
            width: root.width
        }

        CardsPage {
            id: cardsPage

            height: root.height
            width: root.width
        }
    }
/*
    ScreenGestureArea {
        id: screenGestureArea
        anchors.fill: parent
        boundary: Units.gu(3)
        gestureNeeded: "down"
        z: 100
        onGestureFinished: {
            if (gesture === "down") {
                pager.currentIndex = 0;
                gestureNeeded = "up";
            }
            else if (gesture === "up") {
                pager.currentIndex = 1;
                gestureNeeded = "down";
            }
        }
    }
    */
    ListView {
        id: pager
        anchors.fill: parent
        model: pageModel
        highlightRangeMode: ListView.StrictlyEnforceRange
        snapMode: ListView.SnapOneItem
        highlightMoveVelocity: 2000
        // we always start with the card view
        currentIndex: 1
        interactive: false

        onCurrentIndexChanged: console.log("currentIndex = " + currentIndex);
    }

    FlickableHandleArea {
        flickable: pager
        anchors.left: pager.left
        anchors.right: pager.right
        y: 0
        height: Units.length(24)

        onHandleReleased: {
            if( dy > pager.height/2 ) {
                y = pager.height - Units.length(24);
            }
            else if( dy < -pager.height/2 ) {
                y = 0;
            }
        }
    }
}
