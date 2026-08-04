// To parse this JSON data, do
//
//     final walletReportApiModel = walletReportApiModelFromJson(jsonString);

import 'dart:convert';

WalletReportApiModel walletReportApiModelFromJson(String str) => WalletReportApiModel.fromJson(json.decode(str));

String walletReportApiModelToJson(WalletReportApiModel data) => json.encode(data.toJson());

class WalletReportApiModel {
    List<Walletitem>? walletitem;
    String? wallet;
    String? responseCode;
    String? result;
    String? responseMsg;

    WalletReportApiModel({
        this.walletitem,
        this.wallet,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    // Backend (legacyWalletReport) actually sends "wallet_balance" (a number)
    // and "WalletData" (with fields id/amount/balance/description/type/date/
    // reference) — this model previously read "wallet"/"Walletitem", which
    // don't exist in the real response, so the balance and transaction list
    // silently stayed null/empty forever even though User.walletBalance was
    // correct in the database (and correctly visible from the admin panel,
    // which reads that same column directly).
    factory WalletReportApiModel.fromJson(Map<String, dynamic> json) => WalletReportApiModel(
        walletitem: json["WalletData"] == null ? [] : List<Walletitem>.from(json["WalletData"]!.map((x) => Walletitem.fromJson(x))),
        wallet: json["wallet_balance"]?.toString() ?? json["wallet"],
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "Walletitem": walletitem == null ? [] : List<dynamic>.from(walletitem!.map((x) => x.toJson())),
        "wallet": wallet,
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class Walletitem {
    String? message;
    String? status;
    String? amt;

    Walletitem({
        this.message,
        this.status,
        this.amt,
    });

    // Maps the real backend transaction shape (description/type/amount) onto
    // this model's existing field names so the view (which reads
    // item.status/message/amt) needs no changes. `type` is 'credit'/'debit'
    // lowercase from the backend — the view compares status == "Credit".
    // `amount` can be signed (negative for debits); the view already
    // prepends its own +/- based on status, so amt is stored as an
    // unsigned magnitude to avoid a double negative sign on debits.
    factory Walletitem.fromJson(Map<String, dynamic> json) => Walletitem(
        message: json["description"]?.toString() ?? json["message"],
        status: json["type"] != null
            ? (json["type"] == "credit" ? "Credit" : "Debit")
            : json["status"],
        amt: json["amount"] != null
            ? (json["amount"] as num).abs().toString()
            : json["amt"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "status": status,
        "amt": amt,
    };
}
