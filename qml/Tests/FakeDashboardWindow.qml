import QtQuick 2.0
import QtQuick.Controls 1.0
import LunaNext 0.1

FakeWindowBase {
    id: fakeDashboardWindow

    appId: "org.webosports.tests.fakeDashboardWindow"
    windowType: WindowType.Dashboard

    property string appIcon

    height: 50 + Math.random()*50

    property alias scale: windowRectangle.scale

    Rectangle {
        id: windowRectangle

        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "grey" }
            GradientStop { position: 1.0; color: "red" }
        }

        Row {
            anchors.centerIn: parent

            Button {
                text: "OK"
                onClicked: fakeDashboardWindow.destroy()
            }
            Button {
                text: "Cancel"
                checkable: true
            }
        }
    }
}