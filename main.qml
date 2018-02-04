// Memo (мемо) or Pairs (найди пару)
// Игра на развите памяти - отрытие пар карт
// 2016-06-18 Сборка в Qt 5.7 с поддержкой 5.3
// 2018-01-30 Сборка в Qt 5.2 ... (Windows XP x32) + bugfix только четное число карт

import QtQuick 2.2 // 2.3
import QtQuick.Window 2.0

Window {
    id:view
    title: qsTr("MEMO (PAIRS) GAME")
    width: 1024; height: 768; visible: true

    property real ratio: 1.4    // соотношение сторон карты высота/ширина

    property int col:   10
    property int row:   (((col*Math.floor((col*5)/10))%2) ? 1: 0) + Math.floor((col*5)/10)
    property int count: col*row

    property int last           // последняя открытая
    property int opened         // число открытых карт
    property int bad            // число плохих
    property int good           // открыто пар

    property bool debug: false

    signal flip

    Row{ // Управляющие элементы и статистика
        id: header
        anchors{ top: parent.top; left: parent.left;  margins: 10 }
        spacing: 5

        Rectangle{
            height: 30;   width: 120;  radius: 3
            border{ width: 1; color: "black" }
            Text { anchors.centerIn: parent; text: qsTr("START") }
            MouseArea{ anchors.fill: parent; onClicked: { start() } onPressAndHold: debug=!debug }
        }

        Rectangle{
            visible: debug
            height: 30;   width: 120;  radius: 3
            border{ width: 1; color: "black" }
            Text { anchors.centerIn: parent; text: view.ratio>1 ? qsTr("VERTICAL") : qsTr("HORISONTAL") }
            MouseArea{ anchors.fill: parent; onClicked: view.ratio=1/view.ratio }
        }

        Rectangle{
            height: 30;   width: 30;  radius: 3
            border{ width: 1; color: "black" }
            Text { anchors.centerIn: parent; text: qsTr("+") }
            MouseArea{ anchors.fill: parent; onClicked: { if(col<15) col++; start() } }
        }

        Rectangle{
            height: 30;   width: 30;  radius: 3
            border{ width: 1; color: "black" }
            Text { anchors.centerIn: parent; text: qsTr("-") }
            MouseArea{ anchors.fill: parent; onClicked: { if(col>2) col--; start() } }
        }

        Text{
            visible: debug
            font.pixelSize: 20
            text: col + "x" + row + ": [" + count/2 + " pairs]"
                  + " GOOD/BAD: <font color=\"#0000FF\">" + good
                  + "</font> <font color=\"#FF0000\">" + bad
                  + "</font>"
        }
    }

    Rectangle{ // поле для игры
        id: field
        anchors{  top:header.bottom; bottom:parent.bottom; left:parent.left; right:parent.right; margins: 10 }
        color: "#99AA66" //"#226622"
        radius: 10
        border.color: "black"
        border.width: 1
    }

    GridView { // ВСЯ КОЛОДА КАРТ
        id: grid

        property int margin: 10
        property real spacing: 0.1

        property real ratio: (parent.width-margin*2) / (parent.height-margin*2-header.height)
        property real ratios: view.col /(view.ratio * view.row)

        property real m: ratio/ratios

        width:  m<1 ? parent.width-margin*2 : (parent.width-margin*2)/m
        height: m>1 ? parent.height-margin*2-header.height : (parent.height-margin*2-header.height)*m

        anchors{ centerIn: field; margins: grid.margin }

        model: ListModel { id: model }

        cellWidth: width/col
        cellHeight: cellWidth*view.ratio

        delegate: Flipable { // ОДНА ИЗ КАРТ
            id: card

            property bool flipped: true
            property bool pair: !name
            property int xAxis: 0
            property int yAxis: 1
            property int angle: 180
            property int index: current

            width: grid.width/col
            height: width*view.ratio

            state: "back"

            front:
                Rectangle {
                    visible: !card.pair

                    anchors.centerIn: parent
                    height: parent.height*(1-grid.spacing)
                    width: parent.width*(1-grid.spacing)
                    border.width:1
                    border.color:"black"
                    radius: 5

                    color: baseColor
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: parent.width/2
                        text: name
                    }
                }

            back:
                Rectangle {
                    visible: !card.pair
                    anchors.centerIn: parent
                    height: parent.height*(1-grid.spacing)
                    width: parent.width*(1-grid.spacing)
                    border.width:1
                    border.color:"black"
                    radius: 10
                    color: "white"

                    Rectangle{
                        anchors{ fill:parent; margins:5 }
                        radius: 5
                        color: "darkgreen"
                    }

                    Text {
                        visible: debug
                        anchors.centerIn: parent
                        font.pixelSize: parent.width/4
                        text: name
                    }
            }

            transform: Rotation {
                id: rotation; origin.x: card.width / 2; origin.y: card.height / 2
                axis.x: card.xAxis; axis.y: card.yAxis; axis.z: 0
            }

            states: State {
                name: "back"; when: card.flipped
                PropertyChanges { target: rotation; angle: card.angle }
            }

            transitions: Transition {
                NumberAnimation { target: rotation; properties: "angle"; duration: 200 }
            }

            Connections { target: view; onFlip: if(!pair) flipped=true }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(card.pair) return
                    if(opened>1){
                        opened=0
                        view.flip()
                        bad++
                        return
                    }
                    else opened++

                    if(last!=current){
                        card.flipped = !card.flipped
                        if(!last) last = current
                        else check(current,name)
                    }
                }
            }
        }
    }

    function start() // заполнение поля
    {
        last = opened = bad = good = 0
        model.clear()
        var i;
        var v = [];

        for(i=1;i<=(count/2);i++)
            for(var j=0;j<2;j++){
                var n = 0
                do{ n = Math.floor(Math.random()*count); }while(v[n]>0)
                v[n]=i
            }

        for(i=0;i<count;i++)
            model.append({"baseColor":"white", "name": String(v[i]), "current":i+1})
    }

    function check(pos,name) // проверка карты
    {
        if(model.get(last-1).name === model.get(pos-1).name) {
            good++
            opened=0
            model.setProperty(last-1,"name","")
            model.setProperty(pos-1, "name","")
        }
        last = 0
    }

    Component.onCompleted: start()
}
