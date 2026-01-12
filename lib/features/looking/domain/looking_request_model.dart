class LookingRequest {
  final String id;
  final String userId;
  final String category; // 'Player', 'Opponent', 'Umpire', 'Ground', 'Academy'
  final String locationCity;
  final String? skillLevel; // 'Tennis', 'Leather', 'Pro', 'Corporate'
  final String urgencyLevel; // 'Urgent', 'Normal'
  final DateTime? matchDate;
  final String? description;
  final String status; // 'Open', 'Closed'
  final String? contactNumber;
  final DateTime createdAt;
  final Map<String, dynamic>? userProfile; // Joined user data

  LookingRequest({
    required this.id,
    required this.userId,
    required this.category,
    required this.locationCity,
    this.skillLevel,
    this.urgencyLevel = 'Normal',
    this.matchDate,
    this.description,
    this.status = 'Open',
    this.contactNumber,
    required this.createdAt,
    this.userProfile,
  });

  factory LookingRequest.fromMap(Map<String, dynamic> map) {
    return LookingRequest(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      category: map['category'] ?? 'General',
      locationCity: map['location_city'] ?? '',
      skillLevel: map['skill_level'],
      urgencyLevel: map['urgency_level'] ?? 'Normal',
      matchDate: map['match_date'] != null ? DateTime.parse(map['match_date']) : null,
      description: map['description'],
      status: map['status'] ?? 'Open',
      contactNumber: map['contact_number'],
      createdAt: DateTime.parse(map['created_at']),
      userProfile: map['users'] != null ? map['users']['profile_json'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category': category,
      'location_city': locationCity,
      'skill_level': skillLevel,
      'urgency_level': urgencyLevel,
      'match_date': matchDate?.toIso8601String(),
      'description': description,
      'status': status,
      'contact_number': contactNumber,
    };
  }
}
