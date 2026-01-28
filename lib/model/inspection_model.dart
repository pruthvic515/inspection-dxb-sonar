class InspectionModel {
  final int inspectionId;
  final String entityName;
  final String accompaniedBy;
  bool isSelected;

  InspectionModel({
    required this.inspectionId,
    required this.entityName,
    required this.accompaniedBy,
    this.isSelected = false,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      inspectionId: json['inspectionId'],
      entityName: json['entityName'] ?? "",
      accompaniedBy: json['accompaniedBy'] ?? "",
    );
  }
}
