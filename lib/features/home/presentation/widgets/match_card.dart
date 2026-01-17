import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../scoring/domain/match_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final teamA = match.teamA?.name ?? 'Unknown Team';
    final teamB = match.teamB?.name ?? 'Unknown Team';
    final status = match.currentStatus;

    // Fallback initials if logo logic is complex or missing
    final initialA = teamA.isNotEmpty ? teamA[0] : '?';
    final initialB = teamB.isNotEmpty ? teamB[0] : '?';

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.sports_cricket,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              image: match.teamA?.logoUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          match.teamA!.logoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: match.teamA?.logoUrl == null
                                ? Center(
                                    child: Text(
                                      initialA,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 20,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            teamA,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'VS',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              image: match.teamB?.logoUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          match.teamB!.logoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: match.teamB?.logoUrl == null
                                ? Center(
                                    child: Text(
                                      initialB,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 20,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            teamB,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.push('/live-match/${match.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(110, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Watch Live'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
