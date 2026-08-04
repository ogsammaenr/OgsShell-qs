import QtQuick
import Quickshell

Rectangle {
  id: launcherCard

  property bool isOpen: false

  width: isOpen ? 400 : 80
  height: isOpen ? Math.min(48 + (resultsList.count * 44) + (resultsList.count > 0 ? 12 : 0), 320) : 28
  radius: isOpen ? 20 : 14
  opacity: isOpen ? 1.0 : 0.0

  Behavior on width {
    NumberAnimation { duration: 250; easing.type: Easing.OutBack }
  }
  Behavior on height {
    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
  }
  Behavior on radius {
    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
  }
  Behavior on opacity {
    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
  }

  color: theme.bg
  border.color: theme.border
  border.width: 1
  clip: true

  required property var theme
  required property var monitorGroup
  signal closeRequested()

  property string query: ""
  property int selectedIndex: 0

  // Filtered Model for search
  ListModel {
    id: searchModel
  }

  function damerauLevenshtein(s1, s2) {
    var len1 = s1.length;
    var len2 = s2.length;
    if (Math.abs(len1 - len2) > 3) return 99;

    var rowPrev = [];
    var rowCurr = [];
    for (var j = 0; j <= len2; j++) rowPrev[j] = j;

    for (var i = 1; i <= len1; i++) {
      rowCurr[0] = i;
      var char1 = s1.charAt(i - 1);
      for (var j = 1; j <= len2; j++) {
        var cost = (char1 === s2.charAt(j - 1)) ? 0 : 1;
        rowCurr[j] = Math.min(
          rowPrev[j] + 1,
          rowCurr[j - 1] + 1,
          rowPrev[j - 1] + cost
        );
      }
      for (var k = 0; k <= len2; k++) {
        rowPrev[k] = rowCurr[k];
      }
    }
    return rowPrev[len2];
  }

  function evaluateMath(expr) {
    var cleanExpr = expr.replace(/\s+/g, "");
    var safeRegex = /^[0-9+\-*\/%.()]+$/;
    if (!safeRegex.test(cleanExpr)) {
      return null;
    }
    try {
      var fn = new Function("return (" + cleanExpr + ");");
      var res = fn();
      if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
        return res;
      }
    } catch (e) {
      // Syntax error while typing
    }
    return null;
  }

  function filterApps() {
    searchModel.clear();
    var q = query.trim().toLowerCase();
    if (q === "") {
      var limit = Math.min(6, appLauncherService.appList.length);
      for (var i = 0; i < limit; i++) {
        searchModel.append(appLauncherService.appList[i]);
      }
      selectedIndex = 0;
      return;
    }

    var matched = [];

    // Check if query is a dashboard trigger
    if (q === ":apps") {
      matched.push({
        app: {
          name: "Uygulama Kütüphanesini Aç",
          description: "Tüm uygulamaları kategoriler halinde dikey sekmede listeler (:apps)",
          exec: "",
          icon: "",
          desktop_path: "",
          launch_count: 0,
          isDashboardTrigger: true
        },
        score: -2.0, // Always listed first
        name: "Uygulama Kütüphanesini Aç"
      });
    }

    // Check if query is a theme trigger
    if (q === ":theme") {
      matched.push({
        app: {
          name: "Tema Seçim Ekranını Aç",
          description: "Sistem görünümünü ve aktif temayı değiştirir (:theme)",
          exec: "",
          icon: "",
          desktop_path: "",
          launch_count: 0,
          isThemeTrigger: true
        },
        score: -2.0, // Always listed first
        name: "Tema Seçim Ekranını Aç"
      });
    }

    // Check if query is a calculator expression
    if (q.indexOf("=") === 0) {
      var expr = q.substring(1);
      var calcRes = evaluateMath(expr);
      if (calcRes !== null) {
        var formatted = calcRes;
        if (calcRes % 1 !== 0) {
          formatted = parseFloat(calcRes.toFixed(6));
        }
        matched.push({
          app: {
            name: "= " + formatted,
            description: "Sonucu panoya kopyalamak için Enter'a basın",
            exec: "",
            icon: "",
            desktop_path: "",
            launch_count: 0,
            isCalc: true,
            resultText: String(formatted)
          },
          score: -1.0, // Always listed first
          name: "= " + formatted
        });
      }
    }

    var threshold = 0;
    if (q.length <= 2) threshold = 0;
    else if (q.length <= 4) threshold = 1;
    else if (q.length <= 7) threshold = 2;
    else threshold = 3;

    var appListLen = appLauncherService.appList.length;
    for (var i = 0; i < appListLen; i++) {
      var app = appLauncherService.appList[i];
      var nameLower = app.name.toLowerCase();
      var keysLower = (app.search_keys ? app.search_keys.toLowerCase() : "");

      var score = 999;
      var exactMatch = false;

      // 1. Exact matches (score = 0 for prefix, 0.5 for substring)
      if (nameLower.indexOf(q) === 0) {
        score = 0;
        exactMatch = true;
      } else if (nameLower.indexOf(q) !== -1 || keysLower.indexOf(q) !== -1) {
        score = 0.5;
        exactMatch = true;
      }

      // 2. Fuzzy spelling correction match (only when threshold > 0 and not an exact match)
      if (!exactMatch && threshold > 0) {
        var words = (nameLower + " " + keysLower).split(/[\s_\-\.\:\/]+/);
        var minWordDist = 999;

        for (var w = 0; w < words.length; w++) {
          var word = words[w].trim();
          if (word.length === 0) continue;
          if (Math.abs(q.length - word.length) > threshold) continue;

          var dist = damerauLevenshtein(q, word);
          if (dist < minWordDist) {
            minWordDist = dist;
          }
        }

        if (minWordDist <= threshold) {
          score = 1.0 + minWordDist;
        }
      }

      if (score < 99) {
        matched.push({
          app: app,
          score: score,
          name: app.name
        });
      }
    }

    // Sort by match score (best match first), then by launch count (descending), then alphabetically
    matched.sort(function(a, b) {
      if (a.score !== b.score) {
        return a.score - b.score;
      }
      var countA = a.app.launch_count || 0;
      var countB = b.app.launch_count || 0;
      if (countA !== countB) {
        return countB - countA;
      }
      return a.name.localeCompare(b.name);
    });

    var maxCount = Math.min(6, matched.length);
    for (var j = 0; j < maxCount; j++) {
      searchModel.append(matched[j].app);
    }
    selectedIndex = 0;
  }

  onQueryChanged: filterApps()

  onIsOpenChanged: {
    if (isOpen) {
      query = "";
      searchInput.text = "";
      filterApps();
      searchInput.forceActiveFocus();
    }
  }

  Component.onCompleted: {
    filterApps();
    searchInput.forceActiveFocus();
  }

  // Keyboard navigation
  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_Escape) {
      launcherCard.closeRequested();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      if (searchModel.count > 0) {
        selectedIndex = (selectedIndex + 1) % searchModel.count;
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      if (searchModel.count > 0) {
        selectedIndex = (selectedIndex - 1 + searchModel.count) % searchModel.count;
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Return) {
      if (searchModel.count > 0 && selectedIndex >= 0 && selectedIndex < searchModel.count) {
        var item = searchModel.get(selectedIndex);
        if (item.isDashboardTrigger) {
          // Open application dashboard
          monitorGroup.isAppDashboardOpen = true;
        } else if (item.isThemeTrigger) {
          // Open theme selection panel
          monitorGroup.openControlCenterPage("theme");
        } else if (item.isCalc) {
          // Copy calculation result to clipboard on Wayland
          Quickshell.execDetached(["sh", "-c", "echo -n '" + item.resultText + "' | wl-copy"]);
        } else {
          // Log launch statistic asynchronously
          if (item.desktop_path) {
            Quickshell.execDetached([ (Quickshell.env("ROOT_DIR") || "/home/excalibur/WorkSpace/projects/OgsShell-qs") + "/bin/app_launcher_helper", "--launch", item.desktop_path ]);
          }
          // Execute command split by space
          Quickshell.execDetached(item.exec.split(" "));
        }
        launcherCard.closeRequested();
      }
      event.accepted = true;
    }
  }

  Column {
    anchors.fill: parent
    anchors.margins: 6
    spacing: 6
    opacity: launcherCard.isOpen && (launcherCard.width > 150) ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {
      NumberAnimation { duration: 120 }
    }

    // Search Input Pill
    Rectangle {
      width: parent.width
      height: 36
      radius: 18
      color: theme.buttonBg
      border.color: searchInput.activeFocus ? theme.accent : "transparent"
      border.width: 1

      Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Text {
          text: "\uf002"
          color: theme.textSecondary
          font { family: "FiraCode Nerd Font"; pixelSize: 13 }
          anchors.verticalCenter: parent.verticalCenter
        }

        TextInput {
          id: searchInput
          width: parent.width - 40
          color: theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
          verticalAlignment: TextInput.AlignVCenter
          anchors.verticalCenter: parent.verticalCenter
          focus: true

          Text {
            text: "Uygulama arayın..."
            color: "#40ffffff"
            font: parent.font
            visible: parent.text.length === 0 && !parent.activeFocus
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
          }

          onTextChanged: {
            launcherCard.query = text;
          }
        }
      }
    }

    // Results List
    ListView {
      id: resultsList
      width: parent.width
      height: parent.height - 48
      model: searchModel
      spacing: 4
      clip: true
      interactive: false

      delegate: Rectangle {
        width: resultsList.width
        height: 40
        radius: 10
        color: index === selectedIndex ? "#15ffffff" : "transparent"
        border.color: index === selectedIndex ? theme.accent : "transparent"
        border.width: index === selectedIndex ? 1 : 0

        Row {
          anchors.fill: parent
          anchors.margins: 8
          spacing: 12

          // Icon
          Item {
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            Image {
              anchors.fill: parent
              source: model.icon ? "file://" + model.icon : ""
              visible: model.icon !== ""
              fillMode: Image.PreserveAspectFit
              sourceSize.width: 96
              sourceSize.height: 96
              mipmap: true
              smooth: true
              cache: true
            }

            Rectangle {
              anchors.fill: parent
              radius: 4
              color: theme.buttonBg
              visible: model.icon === ""
              Text {
                text: model.name.charAt(0).toUpperCase()
                color: theme.accent
                font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
                anchors.centerIn: parent
              }
            }
          }

          // Name
          Text {
            id: nameText
            text: model.name
            color: theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }

          // Description
          Text {
            text: model.description || ""
            color: theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Normal }
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            elide: Text.ElideRight
            width: Math.max(0, parent.width - nameText.implicitWidth - 64)
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: selectedIndex = index
          onClicked: {
            if (model.isDashboardTrigger) {
              // Open application dashboard
              monitorGroup.isAppDashboardOpen = true;
            } else if (model.isThemeTrigger) {
              // Open theme selection panel
              monitorGroup.openControlCenterPage("theme");
            } else if (model.isCalc) {
              // Copy calculation result to clipboard on Wayland
              Quickshell.execDetached(["sh", "-c", "echo -n '" + model.resultText + "' | wl-copy"]);
            } else {
              // Log launch statistic asynchronously
              if (model.desktop_path) {
                Quickshell.execDetached([ (Quickshell.env("ROOT_DIR") || "/home/excalibur/WorkSpace/projects/OgsShell-qs") + "/bin/app_launcher_helper", "--launch", model.desktop_path ]);
              }
              Quickshell.execDetached(model.exec.split(" "));
            }
            launcherCard.closeRequested();
          }
        }
      }
    }
  }
}
