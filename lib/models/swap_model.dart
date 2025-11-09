class SwapModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookImageUrl;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String status;
  final String message;
  final DateTime createdAt;

  SwapModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImageUrl = '',
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    this.message = '',
    required this.createdAt,
  });

  factory SwapModel.fromMap(Map<String, dynamic> map, String id) {
    return SwapModel(
      id: id,
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      bookImageUrl: map['bookImageUrl'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookImageUrl': bookImageUrl,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'status': status,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
