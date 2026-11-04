import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../.."

FocusScope {
  id: root

  required property var ipc
  property var prompt: null

  signal closeRequested()

  property bool showPassword: false
  property bool rememberChoice: prompt ? prompt.choice_chosen : true
  focus: true

  // Multi-stage auto-focus retry timer to gracefully handle Wayland layer-shell surface activation
  Timer {
    id: focusTimer
    interval: 30
    repeat: true
    running: false
    property int attempts: 0
    onTriggered: {
      attempts++
      let isPass = !prompt || prompt.is_password
      if (isPass) {
        root.forceActiveFocus()
        if (passwordInput.visible) {
          passwordInput.forceActiveFocus()
        }
        if (passwordInput.activeFocus || attempts >= 20) {
          stop()
        }
      } else {
        root.forceActiveFocus()
        unlockBtn.forceActiveFocus()
        if (unlockBtn.activeFocus || attempts >= 20) {
          stop()
        }
      }
    }
  }

  function grabInputFocus() {
    focusTimer.attempts = 0
    let isPass = !prompt || prompt.is_password
    if (isPass) {
      root.forceActiveFocus()
      if (passwordInput.visible) {
        passwordInput.forceActiveFocus()
      }
    } else {
      root.forceActiveFocus()
      unlockBtn.forceActiveFocus()
    }
    focusTimer.restart()
  }

  Component.onCompleted: {
    grabInputFocus()
  }

  onActiveFocusChanged: {
    if (activeFocus) {
      grabInputFocus()
    }
  }

  onVisibleChanged: {
    if (visible) {
      grabInputFocus()
    }
  }

  onPromptChanged: {
    if (prompt) {
      grabInputFocus()
    }
  }

  Keys.onEscapePressed: {
    cancel()
  }

  Keys.onReturnPressed: {
    submit()
  }

  Keys.onEnterPressed: {
    submit()
  }

  function submit() {
    if (!prompt) {
      root.closeRequested()
      return
    }

    if (prompt.is_password) {
      if (ipc) {
        ipc.submitKeyringPassword(prompt.id, passwordInput.text, rememberChoice)
      }
    } else {
      if (ipc) {
        ipc.confirmKeyringAction(prompt.id, true, rememberChoice)
      }
    }
    root.closeRequested()
  }

  function cancel() {
    if (prompt && ipc) {
      ipc.cancelKeyringPrompt(prompt.id)
    }
    root.closeRequested()
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 18
    spacing: 12

    // ==========================================
    // 1. Header (Lock Icon, Title & Description)
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      Rectangle {
        width: 38
        height: 38
        radius: 19
        color: Qt.rgba(Style.accentMagenta.r, Style.accentMagenta.g, Style.accentMagenta.b, 0.16)
        border.color: Qt.rgba(Style.accentMagenta.r, Style.accentMagenta.g, Style.accentMagenta.b, 0.35)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "🔒"
          font.pixelSize: 18
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          Layout.fillWidth: true
          text: (prompt && prompt.title && prompt.title.length > 0) ? prompt.title : "Giriş Anahtarlığının Kilidini Aç"
          font.family: Style.fontDisplay
          font.pixelSize: 13
          font.weight: Font.Bold
          color: Style.textPrimary
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: {
            if (prompt && prompt.description && prompt.description.length > 0) return prompt.description
            if (prompt && prompt.message && prompt.message.length > 0) return prompt.message
            return "Uygulama kayıtlı kimlik bilgilerinize erişmek istiyor."
          }
          font.family: Style.fontDisplay
          font.pixelSize: 11
          color: Style.textMuted
          elide: Text.ElideRight
          wrapMode: Text.WordWrap
          maximumLineCount: 2
        }
      }
    }

    // Optional Warning Banner
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: warningText.implicitHeight + 10
      radius: 8
      color: Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.12)
      border.color: Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.28)
      border.width: 1
      visible: !!(prompt && prompt.warning && prompt.warning.length > 0)

      Text {
        id: warningText
        anchors.fill: parent
        anchors.margins: 6
        text: prompt ? (prompt.warning || "") : ""
        font.family: Style.fontDisplay
        font.pixelSize: 10
        color: Style.accentRed
        wrapMode: Text.WordWrap
      }
    }

    // ==========================================
    // 2. Password Entry Field (with Show/Hide Toggle)
    // ==========================================
    Rectangle {
      id: inputContainer
      Layout.fillWidth: true
      Layout.preferredHeight: 38
      radius: 10
      color: Style.surfaceVariant
      border.color: passwordInput.activeFocus ? Style.accent : Style.appBorder
      border.width: passwordInput.activeFocus ? 1.5 : 1
      visible: !prompt || prompt.is_password

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        acceptedButtons: Qt.LeftButton
        onPressed: mouse => {
          passwordInput.forceActiveFocus()
          mouse.accepted = false
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        Text {
          text: "🔑"
          font.pixelSize: 13
          opacity: 0.7
        }

        TextInput {
          id: passwordInput
          Layout.fillWidth: true
          Layout.fillHeight: true
          verticalAlignment: TextInput.AlignVCenter
          color: Style.textPrimary
          font.family: Style.fontDisplay
          font.pixelSize: 12
          echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
          selectByMouse: true
          focus: true
          cursorVisible: activeFocus

          Keys.onReturnPressed: root.submit()
          Keys.onEnterPressed: root.submit()
          Keys.onEscapePressed: root.cancel()

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: (prompt && prompt.password_new) ? "Yeni anahtarlık parolası girin..." : "Anahtarlık parolasını girin..."
            color: Style.textMuted
            font.family: Style.fontDisplay
            font.pixelSize: 12
            visible: !passwordInput.text && !passwordInput.inputMethodComposing
          }
        }

        // Show/Hide Toggle Icon Button
        MouseArea {
          Layout.preferredWidth: 26
          Layout.preferredHeight: 26
          cursorShape: Qt.PointingHandCursor
          onClicked: root.showPassword = !root.showPassword

          Rectangle {
            anchors.fill: parent
            radius: 6
            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

            Text {
              anchors.centerIn: parent
              text: root.showPassword ? "🙈" : "👁️"
              font.pixelSize: 12
              opacity: 0.85
            }
          }
        }
      }
    }

    // ==========================================
    // 3. Remember Choice Toggle / Checkbox
    // ==========================================
    MouseArea {
      Layout.fillWidth: true
      Layout.preferredHeight: 22
      cursorShape: Qt.PointingHandCursor
      visible: !!(prompt && (prompt.choice_label || prompt.is_password))
      onClicked: root.rememberChoice = !root.rememberChoice

      RowLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
          width: 16
          height: 16
          radius: 4
          color: root.rememberChoice ? Style.accent : Style.surfaceVariant
          border.color: root.rememberChoice ? Style.accent : Style.appBorder
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 10
            font.bold: true
            color: Style.bgPrimary
            visible: root.rememberChoice
          }
        }

        Text {
          Layout.fillWidth: true
          text: (prompt && prompt.choice_label && prompt.choice_label.length > 0) ? prompt.choice_label : "Oturum açıldığında bu anahtarlığı otomatik aç"
          font.family: Style.fontDisplay
          font.pixelSize: 11
          color: Style.textMuted
          elide: Text.ElideRight
        }
      }
    }

    Item { Layout.fillHeight: true }

    // ==========================================
    // 4. Action Buttons (Cancel & Unlock)
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 34
      spacing: 10

      // Cancel Button
      MouseArea {
        id: cancelBtn
        Layout.fillWidth: true
        Layout.fillHeight: true
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.cancel()

        Rectangle {
          anchors.fill: parent
          radius: 8
          color: cancelBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Style.surfaceVariant
          border.color: Style.appBorder
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: (prompt && prompt.cancel_label && prompt.cancel_label.length > 0) ? prompt.cancel_label : "Vazgeç"
            font.family: Style.fontDisplay
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }
      }

      // Unlock / Continue Button
      MouseArea {
        id: unlockBtn
        Layout.fillWidth: true
        Layout.fillHeight: true
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        enabled: !prompt || !prompt.is_password || passwordInput.text.length > 0
        opacity: enabled ? 1.0 : 0.45
        onClicked: root.submit()

        Rectangle {
          anchors.fill: parent
          radius: 8
          color: unlockBtn.containsMouse ? Qt.lighter(Style.accent, 1.1) : Style.accent

          Text {
            anchors.centerIn: parent
            text: (prompt && prompt.continue_label && prompt.continue_label.length > 0) ? prompt.continue_label : (prompt && !prompt.is_password ? "İzin Ver" : "Kilidi Aç")
            font.family: Style.fontDisplay
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Style.bgPrimary
          }
        }
      }
    }
  }
}
