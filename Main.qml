/*
 * Xenoglyph — SDDM (Qt6). The living sigil turns on alien-white skin; the
 * login card hangs from two black horns. Your name echoes in Daedric, the
 * password is a row of red diamonds. A wrong password floods the skin with
 * ichor and shakes the card; a right one whites everything out.
 */
import QtQuick

Item {
    id: root
    width: 1920; height: 1080
    readonly property real u: Math.min(width / 1920, height / 1080)
    readonly property color cInk: "#141016"
    readonly property color cAsh: "#7d7570"
    readonly property color cChitin: "#bfb9b2"
    readonly property color cRed: "#d3122b"
    readonly property color cRedHi: "#ff2b40"
    readonly property color cPearl: "#efedea"
    readonly property bool animated: (config.animated || "true").toString() !== "false"

    property bool   loginPending: false
    property string errorMsg: ""
    property var    sessionNames: []
    property int    sessionIdx: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string sessionLabel: sessionNames.length > sessionIdx ? sessionNames[sessionIdx] : "default session"
    property date   now: new Date()
    property alias  passField: passInput

    FontLoader { id: daedric; source: "fonts/OMWAyembedt.otf" }
    FontLoader { id: departure; source: "fonts/DepartureMonoNerdFont-Regular.otf" }
    readonly property string glyph: daedric.status === FontLoader.Ready ? daedric.font.family : "serif"
    readonly property string mono: departure.status === FontLoader.Ready ? departure.font.family : "monospace"

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Repeater {   // sessionModel exposes names only through delegates
        model: sessionModel
        Item {
            visible: false
            Component.onCompleted: {
                var a = root.sessionNames.slice()
                while (a.length <= index) a.push("")
                a[index] = model.name; root.sessionNames = a
            }
        }
    }
    function cycleSession(d) {
        if (sessionNames.length === 0) return
        sessionIdx = (sessionIdx + d + sessionNames.length) % sessionNames.length
    }
    function doLogin() {
        if (loginPending) return
        if (nameInput.text.length === 0) { nameInput.forceActiveFocus(); return }
        if (passInput.text.length === 0) { passInput.forceActiveFocus(); return }
        loginPending = true; errorMsg = ""
        sddm.login(nameInput.text, passInput.text, sessionIdx)
    }
    function pad(n) { return n < 10 ? "0" + n : "" + n }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginPending = false
            root.errorMsg = "the skin rejects you"
            passInput.text = ""; passInput.forceActiveFocus()
            shake.restart(); flood.restart()
        }
        function onLoginSucceeded() { whiteout.start() }
    }
    Component.onCompleted: {
        nameInput.text = userModel.lastUser
        ;(nameInput.text.length > 0 ? passInput : nameInput).forceActiveFocus()
        wake.start()
    }

    Rectangle { anchors.fill: parent; color: root.cPearl }

    XenoScene {
        id: scene
        anchors.fill: parent
        art: Qt.resolvedUrl("art/")
        running: root.animated
        centerX: width * 0.34
        centerY: height * 0.5
        sigilSize: height * 0.74
        ringText: config.ringText || "XENOGLYPH  INK AND ICHOR  THE VESSEL WAKES  WE WERE WRITTEN BEFORE THE SKIN  "
        assembly: 0
        NumberAnimation on assembly { id: wake; running: false; from: 0; to: 1; duration: 2600; easing.type: Easing.OutCubic }
    }

    // ichor flood on a wrong password
    Rectangle {
        anchors.fill: parent; color: root.cRed; opacity: 0
        SequentialAnimation on opacity {
            id: flood; running: false
            NumberAnimation { to: 0.28; duration: 90 }
            NumberAnimation { to: 0; duration: 900; easing.type: Easing.OutQuad }
        }
    }

    // ---- clock, top right -----------------------------------------------
    Column {
        anchors { right: parent.right; top: parent.top; rightMargin: 64 * root.u; topMargin: 48 * root.u }
        spacing: 4 * root.u
        Text { anchors.right: parent.right; text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())
               font.family: root.mono; font.pixelSize: 44 * root.u; color: root.cInk }
        Text { anchors.right: parent.right; text: Qt.formatDate(root.now, "dddd d MMMM").toLowerCase()
               font.family: root.mono; font.pixelSize: 13 * root.u; color: root.cAsh }
        Text { anchors.right: parent.right; text: Qt.formatDate(root.now, "dddd").toUpperCase()
               font.family: root.glyph; font.pixelSize: 26 * root.u; color: root.cRed }
    }

    // ---- the card ---------------------------------------------------------
    Item {
        id: card
        width: 580 * root.u; height: 680 * root.u
        x: root.width * 0.72 - width / 2
        y: (root.height - height) / 2
        opacity: 0
        transform: Translate { id: jolt }
        NumberAnimation on opacity { running: true; from: 0; to: 1; duration: 1200; easing.type: Easing.OutQuad }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: jolt; property: "x"; to: -18 * root.u; duration: 50 }
            NumberAnimation { target: jolt; property: "x"; to: 14 * root.u; duration: 70 }
            NumberAnimation { target: jolt; property: "x"; to: -8 * root.u; duration: 70 }
            NumberAnimation { target: jolt; property: "x"; to: 4 * root.u; duration: 70 }
            NumberAnimation { target: jolt; property: "x"; to: 0; duration: 80 }
        }

        Image { anchors.fill: parent; source: "art/card.svg"; sourceSize: Qt.size(width, height); smooth: true }

        Column {
            id: form
            x: 100 * root.u; y: 118 * root.u
            width: 380 * root.u
            spacing: 14 * root.u

            Text { text: "XENOGLYPH"; font.family: root.glyph; font.pixelSize: 40 * root.u; font.letterSpacing: 6 * root.u; color: root.cInk }
            Text { text: (config.tagline || "identify the vessel") + "  ·  " + (sddm.hostName || "host")
                   font.family: root.mono; font.pixelSize: 12 * root.u; color: root.cAsh }
            Item { width: 1; height: 10 * root.u }

            // ---- name
            Text { text: "vessel"; font.family: root.mono; font.pixelSize: 11 * root.u; color: root.cAsh }
            Item {
                width: parent.width; height: 40 * root.u
                Text {   // Daedric echo of what you type
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: nameInput.text.toUpperCase(); font.family: root.glyph; font.pixelSize: 22 * root.u
                    color: root.cRed; opacity: 0.85
                }
                TextInput {
                    id: nameInput
                    anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                    font.family: root.mono; font.pixelSize: 18 * root.u; color: root.cInk
                    selectionColor: root.cRed; selectedTextColor: root.cPearl
                    KeyNavigation.tab: passInput
                    onAccepted: passInput.forceActiveFocus()
                }
                Underline { active: nameInput.activeFocus }
            }

            // ---- password: red diamonds
            Text { text: "word"; font.family: root.mono; font.pixelSize: 11 * root.u; color: root.cAsh }
            Item {
                width: parent.width; height: 40 * root.u
                TextInput {
                    id: passInput
                    anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password; color: "transparent"; selectionColor: "transparent"
                    selectedTextColor: "transparent"; cursorVisible: false
                    font.pixelSize: 18 * root.u
                    cursorDelegate: Item {}
                    KeyNavigation.backtab: nameInput
                    onAccepted: root.doLogin()
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6 * root.u
                    Repeater {
                        model: passInput.text.length
                        Rectangle {
                            width: 10 * root.u; height: width; rotation: 45; color: root.cRed
                            antialiasing: true
                            scale: 0
                            NumberAnimation on scale { running: true; from: 0; to: 1; duration: 160; easing.type: Easing.OutBack }
                        }
                    }
                    Rectangle {   // caret: a thin ink thorn that breathes
                        width: 2 * root.u; height: 22 * root.u; color: root.cInk
                        visible: passInput.activeFocus
                        SequentialAnimation on opacity { loops: Animation.Infinite; running: passInput.activeFocus
                            NumberAnimation { to: 0.1; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
                    }
                }
                Underline { active: passInput.activeFocus }
                MouseArea { anchors.fill: parent; onClicked: passInput.forceActiveFocus() }
            }

            // ---- session + caps
            Item {
                width: parent.width; height: 26 * root.u
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10 * root.u
                    Glyphbutton { text: "◂"; onClicked: root.cycleSession(-1) }
                    Text { text: root.sessionLabel.toLowerCase(); font.family: root.mono; font.pixelSize: 13 * root.u; color: root.cInk
                           anchors.verticalCenter: parent.verticalCenter }
                    Glyphbutton { text: "▸"; onClicked: root.cycleSession(1) }
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    visible: typeof keyboard !== "undefined" && keyboard.capsLock
                    text: "caps"; font.family: root.mono; font.pixelSize: 12 * root.u; color: root.cRed
                }
            }

            // ---- wake + error
            Item {
                width: parent.width; height: 96 * root.u
                Column {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - wakeBtn.width - 20 * root.u
                    spacing: 4 * root.u
                    Text { text: root.errorMsg.toUpperCase(); visible: root.errorMsg.length > 0
                           font.family: root.glyph; font.pixelSize: 18 * root.u; color: root.cRed }
                    Text { text: root.errorMsg; visible: root.errorMsg.length > 0; wrapMode: Text.WordWrap; width: parent.width
                           font.family: root.mono; font.pixelSize: 12 * root.u; color: root.cRed }
                }
                Item {
                    id: wakeBtn
                    width: 84 * root.u; height: width
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent; width: parent.width * 0.68; height: width; rotation: 45; antialiasing: true
                        readonly property bool hot: wakeArea.containsMouse || root.loginPending
                        gradient: Gradient {   // glossy, like the window buttons
                            GradientStop { position: 0.0; color: parent.hot ? "#ff7480" : "#3a3340" }
                            GradientStop { position: 0.5; color: parent.hot ? root.cRed : root.cInk }
                            GradientStop { position: 1.0; color: parent.hot ? "#6c0613" : "#050306" }
                        }
                        border.color: parent.hot ? "#6c0613" : root.cRed; border.width: 1
                        RotationAnimator on rotation { running: root.loginPending; from: 45; to: 405; duration: 1400; loops: Animation.Infinite }
                    }
                    Text { anchors.centerIn: parent; text: root.loginPending ? "..." : "wake"
                           font.family: root.mono; font.pixelSize: 13 * root.u; color: root.cPearl }
                    MouseArea { id: wakeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                }
            }
        }
    }

    // ---- power, bottom right ---------------------------------------------
    Row {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 64 * root.u; bottomMargin: 48 * root.u }
        spacing: 26 * root.u
        Power { label: "sleep"; visible: sddm.canSuspend; onClicked: sddm.suspend() }
        Power { label: "reborn"; visible: sddm.canReboot; onClicked: sddm.reboot() }
        Power { label: "unmake"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }

    // success: white-out
    Rectangle {
        id: white; anchors.fill: parent; color: "#f7f6f3"; opacity: 0
        NumberAnimation on opacity { id: whiteout; running: false; to: 1; duration: 700; easing.type: Easing.InQuad }
    }

    component Underline: Item {
        property bool active: false
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 2 * root.u
        Rectangle { width: parent.width; height: 1 * root.u; anchors.bottom: parent.bottom; color: root.cInk; opacity: 0.6 }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
            height: 2 * root.u; color: root.cRed
            width: parent.active ? parent.width : 0
            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
    }
    component Glyphbutton: Text {
        signal clicked
        font.family: root.mono; font.pixelSize: 16 * root.u
        color: ga.containsMouse ? root.cRed : root.cInk
        MouseArea { id: ga; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; onClicked: parent.clicked() }
    }
    component Power: Item {
        property string label
        signal clicked
        width: 64 * root.u; height: 64 * root.u
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; y: 6 * root.u
            width: 22 * root.u; height: width; rotation: 45; antialiasing: true
            color: pa.containsMouse ? root.cRed : "transparent"; border.color: root.cInk; border.width: 1.5
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
               text: parent.label; font.family: root.mono; font.pixelSize: 12 * root.u
               color: pa.containsMouse ? root.cRed : root.cAsh }
        MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }
}
