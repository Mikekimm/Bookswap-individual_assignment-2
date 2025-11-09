class BookModel {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String swapFor;
  final String imageUrl;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final String status;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapFor,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.status = 'available',
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      condition: map['condition'] ?? 'Used',
      swapFor: map['swapFor'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? condition,
    String? swapFor,
    String? imageUrl,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    String? status,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      swapFor: swapFor ?? this.swapFor,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
