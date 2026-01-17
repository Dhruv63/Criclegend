import 'package:test/test.dart';
import 'package:criclegend/features/tournament/domain/fixture_generator.dart';
import 'package:criclegend/features/tournament/domain/points_table_service.dart';

void main() {
  group('Fixture Generator', () {
    test('Round Robin generates correct match count for Even teams', () {
      final teams = ['IND', 'AUS', 'ENG', 'SA']; // 4 teams
      final fixtures = FixtureGenerator.generateRoundRobin(
        teamIds: teams,
        startDate: DateTime.now(),
        tournamentId: 'test-tourney',
        matchesPerDay: 2,
        allowBackToBack: true,
      );

      // 4 teams = 6 matches in single round robin
      expect(fixtures.length, 6);
    });

    test('Round Robin generates correct match count for Odd teams', () {
      final teams = ['IND', 'AUS', 'ENG']; // 3 teams
      final fixtures = FixtureGenerator.generateRoundRobin(
        teamIds: teams,
        startDate: DateTime.now(),
        tournamentId: 'test-tourney',
      );

      // 3 teams = 3 matches (A-B, B-C, C-A)
      expect(fixtures.length, 3);
    });

    test('Scheduling Logic respects matches per day', () {
      final teams = [
        'T1',
        'T2',
        'T3',
        'T4',
        'T5',
        'T6',
      ]; // 6 teams -> 15 matches
      final fixtures = FixtureGenerator.generateRoundRobin(
        teamIds: teams,
        startDate: DateTime(2026, 1, 1),
        tournamentId: 'test',
        matchesPerDay: 2,
      );

      // First 2 matches should be on day 1
      final m1 = DateTime.parse(fixtures[0]['match_date']);
      final m2 = DateTime.parse(fixtures[1]['match_date']);
      final m3 = DateTime.parse(fixtures[2]['match_date']);

      expect(m1.day, 1);
      expect(m2.day, 1);
      expect(m3.day, isNot(1)); // Should be day 2
    });
  });

  group('Points Table Service', () {
    test('Correctly calculates Wins/Losses', () {
      final matches = [
        {
          'status': 'Completed',
          'team_a_id': 'A',
          'team_b_id': 'B',
          'winner_team_id': 'A',
          'innings': [],
        },
        {
          'status': 'Completed',
          'team_a_id': 'A',
          'team_b_id': 'C',
          'winner_team_id': 'C',
          'innings': [],
        },
      ];

      final teams = [
        {'id': 'A', 'name': 'Team A'},
        {'id': 'B', 'name': 'Team B'},
        {'id': 'C', 'name': 'Team C'},
      ];

      final table = PointsTableService.calculateStandings(matches, teams, 't1');

      final teamA = table.firstWhere((t) => t['team']['id'] == 'A');
      expect(teamA['matches_played'], 2);
      expect(teamA['won'], 1);
      expect(teamA['lost'], 1);
      expect(teamA['points'], 2); // 2 pts per win
    });

    test('All Out checks full quota for NRR', () {
      // Mock match: A scores 100/10 in 15 overs (All Out). B scores 101/2 in 12 overs.
      final matches = [
        {
          'status': 'Completed',
          'team_a_id': 'A', 'team_b_id': 'B',
          'winner_team_id': 'B',
          'overs': 20, // Match overs
          'innings': [
            {
              'batting_team_id': 'A',
              'bowling_team_id': 'B',
              'total_runs': 100,
              'wickets': 10,
              'overs': 15.0,
            },
            {
              'batting_team_id': 'B',
              'bowling_team_id': 'A',
              'total_runs': 101,
              'wickets': 2,
              'overs': 12.0,
            },
          ],
        },
      ];

      final teams = [
        {'id': 'A', 'name': 'Team A'},
        {'id': 'B', 'name': 'Team B'},
      ];

      final table = PointsTableService.calculateStandings(matches, teams, 't1');
      final statsA = table.firstWhere((t) => t['team']['id'] == 'A');

      // Team A Analysis:
      // Scored: 100
      // Faced: Should be 120 balls (20.0 overs) because All Out, NOT 90 balls (15.0)
      // NRR = (100/20) - (101/12) = 5.0 - 8.41 = -3.41

      // Calculate internal values from Service logic logic
      // Service internal: oversFaced is in balls.
      // We can't access internal state directly but can deduce from NRR.

      double nrrA = statsA['net_run_rate'];
      double expectedRunRateA = 100 / 20.0; // 5.0
      double expectedConcededRateA = 101 / 12.0; // 8.4166

      expect(nrrA, closeTo(expectedRunRateA - expectedConcededRateA, 0.01));
    });
  });
}
