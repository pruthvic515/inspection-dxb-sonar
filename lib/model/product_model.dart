class ProductModel {
  int id;
  String productName;
  int quantity;
  List<String?>? serialNumber;
  List<String?>? size;

  ProductModel(
      {required this.id,
      required this.productName,
      required this.serialNumber,
      required this.quantity,
      required this.size});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      productName: json['productName'],
      serialNumber: json['serialNumber'],
      quantity: json['quantity'],
      size: json['size'],
    );
  }
}
