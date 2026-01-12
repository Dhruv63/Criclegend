import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/fixture_generator.dart';
import '../data/tournament_repository.dart';
import '../../../../core/theme/app_colors.dart';

class GenerateFixturesScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const GenerateFixturesScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<GenerateFixturesScreen> createState() => _GenerateFixturesScreenState();
}

class _GenerateFixturesScreenState extends ConsumerState<GenerateFixturesScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<Map<String, dynamic>> _allTeams = [];
  final Set<String> _selectedTeamIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    // In a real app, fetch teams linked to this tournament or all available teams
    // For now, fetching ALL teams to let user pick
    final res = await Supabase.instance.client.from('teams').select('id, name, logo_url').limit(50);
    if (mounted) {
      setState(() {
        _allTeams = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    }
  }

  Future<void> _generate() async {
    if (_selectedTeamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 2 teams')));
      return;
    }

    final fixtures = FixtureGenerator.generateRoundRobin(
      teamIds: _selectedTeamIds.toList(),
      startDate: _selectedDate,
      tournamentId: widget.tournamentId,
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Fixtures'),
        content: Text('Generated ${fixtures.length} matches starting from ${_selectedDate.toLocal().toString().split(' ')[0]}.\n\nSave to Database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.premiumRed, foregroundColor: Colors.white),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(tournamentRepositoryProvider).bulkCreateMatches(fixtures);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fixtures Generated Successfully! 📅')));
          Navigator.pop(context); // Go back to Tournament Detail
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-Schedule Generator')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text("Start Date"),
                subtitle: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: Text("Select Teams for Round Robin:", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allTeams.length,
              itemBuilder: (ctx, i) {
                final team = _allTeams[i];
                final isSelected = _selectedTeamIds.contains(team['id']);
                return CheckboxListTile(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  title: Text(team['name']),
                  secondary: CircleAvatar(
                    backgroundImage: team['logo_url'] != null ? NetworkImage(team['logo_url']) : null,
                    child: team['logo_url'] == null ? const Icon(Icons.shield) : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedTeamIds.add(team['id']);
                      } else {
                        _selectedTeamIds.remove(team['id']);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton.icon(
                 icon: const Icon(Icons.auto_fix_high),
                 label: Text("Generate ${_selectedTeamIds.length > 1 ? 'Schedule' : ''}"),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.premiumRed,
                   foregroundColor: Colors.white,
                 ),
                 onPressed: _generate,
               ),
            ),
          ),
        ],
      ),
    );
  }
}
