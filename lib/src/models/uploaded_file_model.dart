class UploadedFileModel {
  final String fileName;
  final String url;
  // Constructor
  UploadedFileModel({
    required this.fileName,
    required this.url,
  });

  // Convert UploadedFileModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'url': url,
    };
  }

  // Create UploadedFileModel from a Map
  factory UploadedFileModel.fromMap(Map<String, dynamic> map) {
    return UploadedFileModel(
      fileName: map['fileName'] as String,
      url: map['url'] as String,
    );
  }
}