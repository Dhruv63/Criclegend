class Team {
  final String id;
  final String name;
  final String? captainId;
  final String? logoUrl;
  final List<dynamic> playersArray;

  // Convenience Getter for UI
  List<dynamic> get players => playersArray;

  Team({
    required this.id,
    required this.name,
    this.captainId,
    this.logoUrl,
    this.playersArray = const [],
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      captainId: json['captain_id'],
      logoUrl: json['logo_url'],
      playersArray: json['players_array'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'captain_id': captainId,
      'logo_url': logoUrl,
      'players_array': playersArray,
    };
  }
}
