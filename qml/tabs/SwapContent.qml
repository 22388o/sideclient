import QtQuick 2.11
import QtQuick.Controls 2.11
import QtQuick.Layouts 1.11
import "../custom-elements"
import "../style"
import "../dialogs"

TabBase {
    id: root

    property var tabs: {
        "swapRequest" : 0,
        "awaitingQuote" : 1,
        "offerReview" : 2,
        "success" : 3,
    }

    property var selectedDelivery: assetsList.length === 0 ? undefined : assetsList[deliver.currentIndex]
    property bool hasDelivery: selectedDelivery !== undefined
    property var receivingList: []
    property var selectedReceive: receivingList.length === 0 ? undefined : receivingList[receive.currentIndex]

    property var assetsList: []
    property var availableAssets: []

    property var currentOrder: undefined
    property var rfq: undefined

    property int networkFee: 0
    property int serverFee: 0

    property string price:  if (currentOrder === undefined || currentOrder.buy_amount === null) {
                            return qsTr("Awaiting Quote");
                        } else if (root.selectedDelivery.ticker === "L-BTC") {
                            return toPrice(currentOrder.buy_amount / (Number(amount.text) * 100000000))
                        } else {
                            return toPrice((Number(amount.text) * 100000000) / currentOrder.buy_amount)
                        }

    Connections {
        target: netManager

        onWalletInfoChanged: {
            const stateInfo = JSON.parse(data)

            if (stateInfo.balances) {
                const balanceInfo = JSON.parse(stateInfo.balances)
                let newList = {}
                for (let balance in balanceInfo) {
                    newList[root.getAppCurrency(balance)] = Number(balanceInfo[balance])
                }
                availableAssets = newList;
            }
            else {
                availableAssets = [];
            }

            updateAssetsList(assetsList)

            encDialog.visible = stateInfo.show_password_prompt

            if (root.rfq === undefined && stateInfo.status !== "OfferRecv") {
                return;
            }

            switch (stateInfo.status) {
                case "OfferRecv":
                    root.rfq = stateInfo.rfq_offer;
                    break;
                case "WaitTxInfo":
                    break;
                case "WaitPsbt":
                    btnAcceptSwap.enabled = true;
                    update_fee(stateInfo);
                    changeTab(tabs.offerReview);
                    break;
                case "WaitSign":
                    break;
                case "Done":
                    changeTab(tabs.success);
                    currentOrder = undefined;
                    root.rfq = undefined;
                    break;
                case "Failed":
                    changeTab(tabs.swapRequest);
                    currentOrder = undefined;
                    root.rfq = undefined;
                    if (encDialog.visible) encDialog.close()
                    break;
                default:
                    console.log("unknown state: " + stateInfo.status)
                    break;
            }
        }

        onUpdateRfqClient: {
            const order = JSON.parse(data);
            if ( root.rfq !== undefined) {
                return;
            }

            switch (order.status) {
            case "Pending": {
                currentOrder = order;

                changeTab(tabs.awaitingQuote);
                timer.start();
            }
            break;
            case "Expired": {
                currentOrder = undefined;
                changeTab(tabs.swapRequest);
            }
            break;
            }
        }

        onAssetsChanged: {
            const assetsInfo = JSON.parse(data);
            updateAssetsList(assetsInfo.assets)
        }

        onUpdateWalletsList: {
            let wallets = JSON.parse(data).configs;
            requireWallet.visible = (wallets.length === 0);
        }
    }

    RowLayout {
        id: requireWallet
        visible: assetsList.length === 0

        anchors{
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 10
            leftMargin: 10
            rightMargin: anchors.leftMargin
        }

        Image {
            Layout.preferredHeight: 50
            Layout.preferredWidth: 50
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            sourceSize.width:  width
            sourceSize.height: height
            source: "qrc:/assets/left_icon_blue.png"
        }

        CustLabel {
            Layout.preferredHeight: 50
            Layout.fillWidth: true
            font.pixelSize: 20
            font.bold: false
            text: qsTr("We cannot detect your liquid wallet automatically. " +
                       "Please setup your liquid wallet(s) in the settings bar in order to make possible to use swap functionality in this page.")
            color: Style.dyn.baseActive
            horizontalAlignment: Qt.AlignLeft
            wrapMode: Text.WordWrap
        }
    }

    SwipeView {
        id: stackRoot
        currentIndex: tabs.swapRequest
        anchors{
            fill: parent
            topMargin: 20 + 20 * mainWindow.dynHeightMult
            bottomMargin: 10 + 20 * mainWindow.dynHeightMult
            leftMargin: 20 + 20 * mainWindow.dynWidthMult
            rightMargin: anchors.leftMargin
        }
        interactive: false
        clip: true

        ColumnLayout {
            id: swapRequest

            clip: true
            spacing: 5 + 15 * mainWindow.dynHeightMult

            Item { Layout.fillHeight: true }

            GridLayout {
                Layout.minimumWidth: 660
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: 100
                Layout.maximumHeight: Layout.minimumHeight

                columns: 3
                rows: 2
                rowSpacing: 0

                Layout.alignment: Qt.AlignCenter

                CustLabel {
                    Layout.preferredHeight: 30 + 30 * mainWindow.dynHeightMult
                    Layout.fillWidth: true
                    font.pixelSize: 20
                    font.bold: false
                    text: qsTr("Send")
                    horizontalAlignment: Qt.AlignHCenter
                }

                Item { width: 40}

                CustLabel {
                    Layout.preferredHeight: 30 + 30 * mainWindow.dynHeightMult
                    Layout.fillWidth: true
                    font.pixelSize: 20
                    font.bold: false
                    text: qsTr("Receive")
                    horizontalAlignment: Qt.AlignHCenter
                }

                CustCombobox {
                    id: deliver
                    model: root.assetsList
                    Layout.preferredWidth: 280 + 20 * mainWindow.dynWidthMult
                    Layout.alignment: Qt.AlignRight
                    textRole: "ticker"
                    onCurrentIndexChanged: {
                        let newList = [];
                        for (const i in root.assetsList) {
                            if (Number(i) !== Number(currentIndex)) {
                                newList.push(root.assetsList[i]);
                            }
                        }
                        root.receivingList = newList;
                        amount.clear();
                    }
                }

                Item {
                    Layout.preferredWidth: 40
                    height: 40

                    CustIconButton {
                        anchors.centerIn: parent

                        width: 40
                        height: 40
                        offset: 10
                        showBckgrnd: false

                        source: "qrc:/assets/data_exchange_arrows.png"
                        onClicked: {
                            for (const i in root.assetsList) {
                                if (root.assetsList[i].ticker === selectedReceive.ticker) {
                                    deliver.currentIndex = i;
                                    break;
                                }
                            }
                        }
                    }
                }

                CustCombobox {
                    id: receive
                    model: root.receivingList
                    Layout.preferredWidth: 280 + 20 * mainWindow.dynWidthMult
                    Layout.alignment: Qt.AlignLeft
                    textRole: "ticker"
                }
            }

            Item { Layout.preferredHeight: 5 + 15 * mainWindow.dynHeightMult }

            Row {
                Layout.alignment: Qt.AlignCenter
                spacing: 10

                ColumnLayout {
                    width: 350

                    CustLabel {
                        text: qsTr("Amount")
                        Layout.leftMargin: 5
                        horizontalAlignment: Qt.AlignLeft
                        font.pixelSize: 16
                        Layout.fillWidth: parent.width
                    }

                    CustBalanceInput {
                        id: amount
                        Layout.preferredHeight: 50
                        Layout.fillWidth: parent.width
                        upperBound: root.hasDelivery? Number(root.selectedDelivery.amount / 100000000) : 0
                        decimals: root.hasDelivery? root.selectedDelivery.precision : 0
                        leftPadding: 20

                        Image {
                            width: 20
                            height: 20
                            sourceSize.width:  width
                            sourceSize.height: height
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            source: (selectedDelivery !== undefined) ? "data:image/png;base64," + selectedDelivery.icon : ""
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: parent.width
                        Layout.leftMargin: 5
                        Layout.rightMargin: 10

                        CustLabel {
                            text: qsTr("Available amount")
                            horizontalAlignment: Qt.AlignLeft
                            font.bold: false
                            font.pixelSize: 14
                            color: Style.dyn.disabledFontColor
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        CustLabel {
                            Layout.alignment: Qt.AlignRight
                            text: root.selectedDelivery !== undefined
                                  ? fromSatoshi(root.selectedDelivery.amount, root.selectedDelivery.precision) : ""
                            font.pixelSize: 14
                        }
                    }
                }

                CustButton {
                    id: apply
                    text: qsTr("MAX")
                    implicitHeight: 50
                    implicitWidth: 100
                    onClicked: amount.text = (root.selectedDelivery.amount / 100000000)
                    baseColor: Style.dyn.helpColor
                    fontColor: "black"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.preferredHeight: 5 + 15 * mainWindow.dynHeightMult }

            CustButton {
                id: startSwapButton
                Layout.preferredWidth: 120 + 30 * mainWindow.dynHeightMult
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignCenter

                radius: 150
                font.pixelSize: 20
                text: qsTr("Request")
                borderOffset: 12
                baseColor: Style.dyn.baseActive
                enabled: amount.acceptableInput

                onClicked: netManager.createRfq(selectedDelivery.asset_id,
                                            Number(amount.text * 100000000),
                                            selectedReceive.asset_id);
            }

            Item { Layout.fillHeight: true }

            Keys.onPressed: {
                if (event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return) {
                    return;
                }

                if (startSwapButton.enabled) {
                    startSwapButton.clicked();
                }
            }
        }

        ColumnLayout {
            id: rfqCreated

            clip: true
            spacing: 5 + 15 * mainWindow.dynHeightMult

            Item { Layout.fillHeight: true }

            CustLabel {
                text: qsTr("Best Quote")
                Layout.fillWidth: true
                font.pixelSize: 30
                horizontalAlignment: Qt.AlignHCenter
            }

            CustQuoteBoard {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 160 + 20 * mainWindow.dynHeightMult

                sourceIcon: (selectedDelivery !== undefined) ? "data:image/png;base64," + selectedDelivery.icon : ""
                destIcon: (selectedReceive !== undefined) ? "data:image/png;base64," + selectedReceive.icon : ""
                price: root.price
                deliver: if (currentOrder !== undefined)
                             qsTr("Deliver %1 %2")
                                .arg(formatNumber(amount.text, root.selectedDelivery.precision))
                                .arg(selectedDelivery.ticker)
                         else ""
                receive:  if (currentOrder !== undefined && Number(currentOrder.buy_amount) !== 0)
                              qsTr("Receive %1 %2")
                                .arg(fromSatoshi(currentOrder.buy_amount, root.selectedReceive.precision))
                                .arg(selectedReceive.ticker)
                          else qsTr("No quotes")
            }

            Rectangle {
                radius: 5
                width: 400
                height: 140
                Layout.alignment: Qt.AlignCenter

                color: Style.dyn.baseGrey

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 20

                    columns: 2
                    rows: 3
                    Repeater {
                        id: awaitingQuoteRep
                        delegate: CustLabel {
                            text: modelData
                            Layout.fillWidth: true
                            font.pixelSize: 18
                            font.bold: index % 2
                            horizontalAlignment: index % 2 ? Qt.AlignRight : Qt.AlignLeft
                        }
                    }
                }
            }

            CustProgressBar {
                id: progressRfq
                width: 400
                from: 0
                to: 1
                value: 0
                Layout.alignment: Qt.AlignCenter
            }

            CustButton {
                text: qsTr("Cancel")
                Layout.alignment: Qt.AlignCenter
                implicitHeight: 60
                implicitWidth: 180
                baseColor: Style.dyn.baseActive
                font.pixelSize: 18
                onClicked: netManager.cancelRfq(currentOrder.order_id)
            }

            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            id: swapOfferRecieve

            clip: true
            spacing: 5 + 15 * mainWindow.dynHeightMult

            Item { Layout.fillHeight: true }

            CustLabel {
                text: qsTr("Confirm swap")
                Layout.fillWidth: true
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: 30
            }

            CustQuoteBoard {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 160 + 20 * mainWindow.dynHeightMult

                sourceIcon: (selectedDelivery !== undefined) ? "data:image/png;base64," + selectedDelivery.icon : ""
                destIcon: (selectedReceive !== undefined) ? "data:image/png;base64," + selectedReceive.icon : ""
                price: root.price
                deliver: if (rfq !== undefined )
                             qsTr("Deliver %1 %2")
                                .arg(fromSatoshi(rfq.swap.sell_amount, root.selectedDelivery.precision))
                                .arg(assetsNameByAssetId(rfq.swap.sell_asset))
                         else ""

                receive: if (rfq !== undefined )
                             qsTr("Receive %1 %2")
                                .arg(fromSatoshi(rfq.swap.buy_amount, root.selectedReceive.precision))
                                .arg(assetsNameByAssetId(rfq.swap.buy_asset))
                         else ""
            }

            Rectangle {
                radius: 5
                Layout.preferredWidth: 400
                Layout.preferredHeight: 100 + 20 * mainWindow.dynHeightMult
                Layout.alignment: Qt.AlignCenter

                color: Style.dyn.baseGrey

                ColumnLayout {
                    anchors{
                        fill: parent
                        topMargin: 5 + 15 * mainWindow.dynHeightMult
                        bottomMargin: anchors.topMargin
                        leftMargin: 10 + 10 * mainWindow.dynWidthMult
                        rightMargin: anchors.leftMargin
                    }

                    CustLabel {
                        text: qsTr("Commission")
                        Layout.fillWidth: true
                        font.pixelSize: 18
                        horizontalAlignment: Qt.AlignHCenter
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        columns: 2
                        rows: 2

                        Repeater {
                            id: awaitingAcceptRep
                            delegate: CustLabel {
                                text: modelData
                                Layout.fillWidth: true
                                font.pixelSize: 18
                                font.bold: index % 2
                                horizontalAlignment: index % 2 ? Qt.AlignRight : Qt.AlignLeft
                            }
                        }
                    }
                }
            }

            CustProgressBar {
                id: progressSigning
                width: 400
                from: 0
                to: 1
                value: 0
                Layout.alignment: Qt.AlignCenter
            }

            RowLayout {
                id: btns
                property double preferredSize: Math.min(mainWindow.dynHeightMult, mainWindow.dynWidthMult)

                spacing: 20
                Layout.alignment: Qt.AlignCenter

                CustRectButton {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 120 + 40 * btns.preferredSize
                    iconSize: 60 + 20 * btns.preferredSize

                    source: "qrc:/assets/close_cross.png"
                    text:  qsTr("Reject")

                    onClicked:  netManager.swapCancel()
                }

                CustRectButton {
                    id: btnAcceptSwap
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 120 + 40 * btns.preferredSize
                    iconSize: 60 + 20 * btns.preferredSize

                    source: "qrc:/assets/data_exchange_arrows.png"
                    text:  qsTr("Swap")

                    onClicked: {
                        btnAcceptSwap.enabled = false;
                        netManager.swapAccept()
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            id: successPage
            clip: true

            CustSuccessPage {
                Layout.alignment: Qt.AlignCenter

                header: qsTr("Swap completed")
                onBackClicked: changeTab(tabs.swapRequest);
            }
        }

        Item{}

        onVisibleChanged: {
            if (currentIndex === tabs.swapRequest)
                amount.forceActiveFocus();
            else if (currentIndex === tabs.success) {
                root.changeTab(tabs.swapRequest)
            }
        }
        Component.onCompleted: amount.forceActiveFocus();
    }

    onEnsureFocus: amount.forceActiveFocus();

    Timer {
        id: timer
        interval: 25;
        running: false;
        repeat: true
        onTriggered: {
            if (currentOrder === undefined) {
                stop();
                return;
            }

            if (root.rfq !== undefined) {
                progressSigning.from = 0
                progressSigning.to = root.rfq.expires_at - root.rfq.created_at
                progressSigning.value = new Date() - root.rfq.created_at;
                if (encDialog.visible) {
                    progressConfirm.from = progressSigning.from
                    progressConfirm.to = progressSigning.to
                    progressConfirm.value = progressSigning.value
                }
                if (progressSigning.value >= progressSigning.to) stop();
            } else if (currentOrder !== undefined) {
                progressRfq.from = 0
                progressRfq.to = currentOrder.expires_at - currentOrder.created_at
                progressRfq.value = new Date() - currentOrder.created_at;
                if (progressRfq.value >= progressRfq.to) stop();
            } else {
                stop();
            }
        }
    }

    DialogCheckEncryption {
        id: encDialog
        parent: mainContentItem

        onAccepted: netManager.setPassword(passphrase);
        onCanceled: netManager.cancelPassword();
    }

    function getAppCurrency(nodeCurrency) {
        return nodeCurrency === 'bitcoin' ? "L-BTC" : nodeCurrency
    }

    function assetsNameByAssetId(assetId) {
        for (let i in assetsList) {
            if (assetsList[i].asset_id === assetId) {
                return assetsList[i].ticker;
            }
        }
        return "";
    }

    function updateAssetsList(assets) {
        let fundedAssets = assets;
        for (let i in fundedAssets) {
            let asset = fundedAssets[i];
            if (typeof availableAssets[asset.asset_id] === undefined) {
                asset.amount = 0;
            } else {
                asset.amount = availableAssets[asset.asset_id];
            }
        }
        assetsList = fundedAssets;
    }

    function update_fee(stateInfo) {
        let lbtcOut = ({});
        if (selectedDelivery.ticker === "L-BTC") {
            lbtcOut = stateInfo.own_outputs;
        } else {
            lbtcOut = stateInfo.contra_outputs;
        }

        for ( let i in lbtcOut ) {
            const out = lbtcOut[i];
            if (out.output_type === "NetworkFee") {
                root.networkFee = Number(out.amount);
            } else if (out.output_type === "ServerFee"){
                root.serverFee = Number(out.amount);
            }
        }
    }

    function changeTab(newIndex) {
        let oldIndex = stackRoot.currentIndex;

        if (newIndex === oldIndex) {
            return;
        }

        stackRoot.currentIndex = newIndex;

        if (newIndex === 0) {
            amount.clear();
            amount.forceActiveFocus();
        } else if (newIndex === 1) {
            let swapInfo = qsTr("L-BTC / %2")
            .arg(root.selectedDelivery.ticker === "L-BTC"
                 ? root.selectedReceive.ticker
                 : root.selectedDelivery.ticker)
            awaitingQuoteRep.model = [
                "Swap",
                swapInfo,
                "Sell",
                root.selectedDelivery.ticker,
                "Quantity",
                amount.text
            ]
        } else if (newIndex === 2) {
            awaitingAcceptRep.model = [
                "Swap fee",
                qsTr("%1 L-BTC").arg(fromSatoshi(serverFee, 8)),
                "Transaction fee",
                qsTr("%1 L-BTC").arg(fromSatoshi(networkFee, 8))
            ]
        }
    }
}
