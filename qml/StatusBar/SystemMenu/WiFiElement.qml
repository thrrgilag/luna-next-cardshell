/* @@@LICENSE
*
*      Copyright (c) 2009-2013 LG Electronics, Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* LICENSE@@@ */

import QtQuick 2.0
import LunaNext.Common 0.1

Drawer {
    id: wifiMenu
    property int ident:         0
    property int internalIdent: 0

    property bool isWifiOn: true
    property bool coloseOnConnect: false

    // ------------------------------------------------------------
    // External interface to the WiFi Element is defined here:

    signal menuCloseRequest(int delayMs)
    signal menuOpened()
    signal menuClosed()
    signal onOffTriggered()
    signal prefsTriggered()
    signal itemSelected(int index, string name, int profileId, string securityType, string connState)

    function setWifiState(isOn, state) {
        if(!isWifiOn && isOn) {
            if(wifiMenu.state == "DRAWER_OPEN") {
                wifiSpinner.on = true;
            }
        }

        isWifiOn = isOn
        wifiTitleState.text = state

        if(!isWifiOn) {
            wifiSpinner.on = false;
            clearWifiList();
        }
    }

    function addWifiNetworkEntry(name, profId, sigBars, secType, connectionStatus, isConnected) {
        wifiList.append({"wifiName": name,
                         "profId":profId,
                         "sigBars": sigBars,
                         "secType": secType,
                         "connectionStatus": connectionStatus,
                         "isConnected": isConnected,
                         "listIndex": wifiList.count,
                         "itemStatus": "",
                         "boldStatus": false,
                         "showSelected": false
                        });
        wifiListView.height = (wifiOnOff.height+separator.height) * wifiList.count;
    }

    function clearWifiList() {
        wifiList.clear()
        wifiListView.height = 1
    }

    function wifiConnectStateUpdate(connected, ssid, state) {
        if(isWifiOn) {
            if(ssid != "") {
                for(var index = 0; index < wifiList.count; index++) {
                    var entry = wifiList.get(index)
                    entry.boldStatus = false;
                    if(entry.wifiName == ssid) {
                        if(state == "userSelected") {
                            entry.connectionStatus = "connecting";
                            entry.isConnected = false;
                            entry.itemStatus = runtime.getLocalizedString("Connecting...");
                            entry.showSelected = true;
                        } else if((state == "associated") || (state == "associating")) {
                            entry.connectionStatus = state;
                            entry.isConnected = false;
                            entry.itemStatus = runtime.getLocalizedString("Connecting...");
                        } else if((state == "ipFailed") || (state == "associationFailed")) {
                            entry.connectionStatus = state;
                            entry.isConnected = false;
                            if(state == "ipFailed") {
                                entry.itemStatus = runtime.getLocalizedString("IP configuration failed");
                                entry.boldStatus = true;
                            } else {
                                entry.itemStatus = runtime.getLocalizedString("Association failed");
                            }
                        } else if(state == "ipConfigured") {
                            entry.connectionStatus = state;
                            entry.isConnected = true;
                            entry.itemStatus = "";
                            if(index != 0) {
                                // move the connected item to the top
                                wifiList.move(index, 0, 1);
                            }

                            if(coloseOnConnect) {
                                menuCloseRequest(1000);
                                coloseOnConnect = false;
                            }
                        } else if(state == "notAssociated") {
                            entry.connectionStatus = "";
                            entry.isConnected = false;
                            entry.itemStatus = "";
                        }
                    } else {
                        entry.isConnected = false;
                        entry.itemStatus = "";
                        entry.connectionStatus = "";
                        entry.showSelected = false;
                    }
                }
            } else if (!connected){
                for(var index = 0; index < wifiList.count; index++) {
                    var entry = wifiList.get(index)
                    entry.isConnected = false;
                    entry.boldStatus = false;
                }
            }
        }
    }

    /*
    Connections {
        target: NativeSystemMenuHandler

        onWifiListUpdated:  {
            wifiSpinner.on = false;
        }
    }
    */

    function joinWifi(ssid) {
        service.call("luna://com.palm.wifi/connect",
                     JSON.stringify(
                         {"ssid":ssid,"security":{"simpleSecurity":{"passKey":""}}
                         }),
                     function(message) {
                         var response = JSON.parse(message.payload);
                         console.log("WiFi connect response: " + JSON.stringify(response));
                     },
                     function(error) {
                         console.log("Could not join wifi network: " + error)
                     });
        console.log("join done I think");
    }

    function enableWifi(enable) {
        service.call("luna://com.palm.wifi/setstate",
                     JSON.stringify({"state":enable ? "enabled" : "disabled"}),
                     function(message) {
                         //var response = JSON.parse(message.payload);
                         //setWifiState(enable, enable ? "ON" : "OFF");
                         updateWifiStatus();
                     },
                     function(error) {
                         console.log("Could not switch wifi state: " + error);
                     });
    }

    function findWifiNetworks() {
        clearWifiList();
        service.call("luna://com.palm.wifi/findnetworks",
                     JSON.stringify({}),
                     function(message) {
                         var response = JSON.parse(message.payload);
                         for (var i = 0; i < response.foundNetworks.length; i++) {
                             var name = response.foundNetworks[i].networkInfo.ssid;
                             var profId = response.foundNetworks[i].networkInfo.profileId;
                             var sigBars = response.foundNetworks[i].networkInfo.signalBars;
                             var secType = response.foundNetworks[i].networkInfo.availableSecurityTypes[0];
                             var connectionStatus = response.foundNetworks[i].networkInfo.connectState;
                             var isConnected = connectionStatus === "ipConfigured";
                             addWifiNetworkEntry(name, profId, sigBars, secType, connectionStatus, isConnected);
                         }
                         wifiSpinner.on = false;
                     },
                     function(error) {
                         console.log("Could not find networks: " + error);
                     });
    }

    function updateWifiStatus() {
        service.subscribe("luna://com.palm.wifi/getstatus",
                     JSON.stringify({"subscribe":true}),
                     function(message) {
                         var response = JSON.parse(message.payload);
                         switch(response.status) {
                         case "connectionStateChanged":
                             setWifiState(true, response.networkInfo.ssid);
                             break;
                         case "serviceEnabled":
                             setWifiState(true, "ON");
                             break;
                         case "serviceDisabled":
                             setWifiState(false, "OFF");
                         }
                     },
                     function(error) {
                         console.log("Could not retrieve mute status: " + error);
                     });
    }

    LunaService {
        id: service
        name: "org.webosports.luna"
        usePrivateBus: true
        onInitialized: updateWifiStatus()
    }

    // ------------------------------------------------------------


    width: parent.width

    onDrawerOpened: menuOpened()
    onDrawerClosed: menuClosed()

    onDrawerFinishedClosingAnimation: {
        clearWifiList();
    }

    drawerHeader:
    MenuListEntry {
        selectable: wifiMenu.active
        content: Item {
                    width: parent.width;

                    Text{
                        id: wifiTitle
                        x: ident;
                        anchors.verticalCenter: parent.verticalCenter
                        // text: runtime.getLocalizedString("Wi-Fi");
                        text: "Wi-Fi"
                        color: wifiMenu.active ? "#FFF" : "#AAA";
                        font.bold: false;
                        font.pixelSize: FontUtils.sizeToPixels("medium") // 18
                        font.family: "Prelude"
                    }

                    Spinner {
                        id: wifiSpinner
                        width: Units.gu(3.2)
                        height: Units.gu(3.2)
                        x: wifiTitle.width + Units.gu(1.8); 
                        anchors.verticalCenter: parent.verticalCenter
                        on:false
                    }

                    Text {
                        id: wifiTitleState
                        x: wifiMenu.width - width - Units.gu(1.4); 
                        anchors.verticalCenter: parent.verticalCenter
                        //text: runtime.getLocalizedString("init");
                        text: "init"
                        width: wifiMenu.width - wifiTitle.width - Units.gu(6.0)
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight;
                        color: "#AAA";
                        font.pixelSize: FontUtils.sizeToPixels("small") //13
                        font.family: "Prelude"
                        font.capitalization: Font.AllUppercase
                    }
                }
    }

    drawerBody:
    Column {
        spacing: 0
        width: parent.width

        MenuDivider  { id: separator }

        MenuListEntry {
            id: wifiOnOff
            selectable: true
            content: Text {  id: wifiOnOffText;
                             x: ident + internalIdent;
                             //text: isWifiOn ? runtime.getLocalizedString("Turn off WiFi") : runtime.getLocalizedString("Turn on WiFi");
                             text: isWifiOn ? "Turn off WiFi" : "Turn on WiFi"
                             color: "#FFF";
                             font.bold: false;
                             font.pixelSize: FontUtils.sizeToPixels("medium") //18
                             font.family: "Prelude"
                         }

            onAction: {
                onOffTriggered()
                wifiSpinner.on = !isWifiOn;
                if(isWifiOn) {
                    enableWifi(false);
                    menuCloseRequest(300);
                } else {
                    enableWifi(true);
                    coloseOnConnect = true;
                }
            }
        }

        MenuDivider {}

        ListView {
            id: wifiListView
            width: parent.width
            interactive: false
            spacing: 0
            height: Units.gu(0.1)
            model: wifiList
            delegate: wifiListDelegate
        }

        MenuListEntry {
            selectable: true
            content: Text {
                x: ident + internalIdent
                //text: runtime.getLocalizedString("Wi-Fi Preferences")
                text: "Wi-Fi Preferences"
                color: "#FFF"; font.bold: false; font.pixelSize: FontUtils.sizeToPixels("medium"); font.family: "Prelude"}
                //color: "#FFF"; font.bold: false; font.pixelSize: 18; font.family: "Prelude"}
            onAction: {
                clearWifiList()
                prefsTriggered()
                menuCloseRequest(300);
            }
        }
    }

    Component {
        id: wifiListDelegate
        Column {
            spacing: 0
            width: parent.width
            property int index: listIndex

            MenuListEntry {
                id: entry
                selectable: true
                forceSelected: showSelected

                content: WifiEntry {
                            id: wifiNetworkData
                            x: ident + internalIdent;
                            width: wifiMenu.width-x;
                            name:         wifiName;
                            profileId:    profId;
                            signalBars:   sigBars;
                            securityType: secType;
                            connStatus:   connectionStatus;
                            status:       itemStatus;
                            statusInBold: boldStatus;
                            connected:    isConnected;
                         }
                onAction: {
                    itemSelected(index,
                                 wifiNetworkData.name,
                                 wifiNetworkData.profileId,
                                 wifiNetworkData.securityType,
                                 wifiNetworkData.connStatus)

                    if((wifiNetworkData.connStatus == "ipConfigured") ||
                       (wifiNetworkData.connStatus == "associated") ||
                       (wifiNetworkData.connStatus == "ipFailed") ||
                       (wifiNetworkData.connStatus == "associationFailed")  ) {
                        menuCloseRequest(300);
                    } else if((wifiNetworkData.profileId == 0) && (wifiNetworkData.securityType != "")) {
                        menuCloseRequest(300);
                    }

                    menuCloseRequest(300);
                    coloseOnConnect = true;
                }
            }

            MenuDivider {}
        }

    }

    ListModel {
        id: wifiList
    }

    onMenuOpened: {
        coloseOnConnect = false;
        if(isWifiOn) {
            wifiSpinner.on = true
            findWifiNetworks();
        }
    }

    onMenuClosed: {
        coloseOnConnect = false;
        wifiSpinner.on = false
    }
}

