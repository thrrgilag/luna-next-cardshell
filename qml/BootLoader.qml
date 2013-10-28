/*
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
import LunaNext 0.1

Item {
    property Loader shellLoader

    LunaService {
        id: systemService
        name: "org.webosports.luna"
        onInitialized: {
            console.log("Calling boot status service ...");
            systemService.subscribe("luna://com.palm.systemmanager/getBootStatus",
                                    JSON.stringify({"subscribe":true}),
                                    handleBootStatusChanged,
                                    handleError);
        }

        function handleBootStatusChanged(data) {
            var response = JSON.parse(data);

            if( response.hasOwnProperty("firstUse") ) {
                if( response.firstUse ) {
                    shellLoader.source = "FirstUseShell.qml";
                }
                else {
                    shellLoader.source = "CardShell.qml";
                }
            }
        }

        function handleError(message) {
            console.log("Failed to call boot status service: " + message);
        }
    }

    // Boot screen animation
    Rectangle {
        id: bootScreenItem

        color: "black"

        anchors.fill: parent

        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }

        Image {
            id: logoNormal
            anchors.centerIn: parent
            source: "images/webosports-logo-normal.png"
            width: parent.width/2
            height: parent.height/2
        }

        Image {
            id: logoGlow
            anchors.centerIn: logoNormal
            source: "images/webosports-logo-glow.png"
            width: logoNormal.width
            height: logoNormal.height
            opacity: 0.1
        }

        SequentialAnimation {
            id: loadingAnimation
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                target: logoGlow
                properties: "opacity"
                from: 0.1
                to: 1.0
                easing.type: Easing.Linear
                duration: 700
            }

            NumberAnimation {
                target: logoGlow
                properties: "opacity"
                from: 1.0
                to: 0.1
                easing.type: Easing.Linear
                duration: 700
            }
        }

        // After 3 second, fade out to show the shell
        Timer {
            interval: 3000
            running: true
            repeat: false
            onTriggered: bootScreenItem.opacity = 0;
        }
    }
}
