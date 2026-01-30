import 'dart:convert';
import 'outlet_model.dart';

StoreOutletDataModel outletsFromJson(String str) =>
    StoreOutletDataModel.fromJson(jsonDecode(str));

class StoreOutletDataModel {
  List<OutletData> data;

  StoreOutletDataModel({
    required this.data,
  });

  factory StoreOutletDataModel.fromJson(Map<String, dynamic> json) {
    return StoreOutletDataModel(
      data: List<OutletData>.from(
          json['data'].map((x) => OutletData.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data.toList();
    return data;
  }
}
