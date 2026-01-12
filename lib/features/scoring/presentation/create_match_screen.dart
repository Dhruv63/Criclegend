import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../scoring/data/scoring_provider.dart';
import '../../scoring/domain/team_model.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _oversController = TextEditingController(text: '20');
  final _groundController = TextEditingController(); // location
  
  Team? _teamA;
  Team? _teamB;

  // Toss Logic
  Team? _tossWinner;
  String _tossDecision = 'Bat'; // Bat or Bowl
  
  bool _isLoading = false;

  @override
  void dispose() {
    _oversController.dispose();
    _groundController.dispose();
    super.dispose();
  }

  // Helper to pick a team (Mocked Dialog for now, ideally full search)
  void _pickTeam(bool isTeamA) async {
    final teams = await ref.read(scoringRepositoryProvider).getMyTeams();
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Team'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: teams.length + 1,
              itemBuilder: (context, index) {
                if (index == teams.length) {
                   return ListTile(
                     leading: const Icon(Icons.add),
                     title: const Text('Create New Team'),
                     onTap: () async {
                       Navigator.pop(context);
                       _createNewTeam(isTeamA);
                     },
                   );
                }
                final team = teams[index];
                return ListTile(
                  title: Text(team.name),
                  onTap: () {
                    setState(() {
                      if (isTeamA) _teamA = team; else _teamB = team;
                      
                      // Reset toss if team changed
                      if (_tossWinner?.id != _teamA?.id && _tossWinner?.id != _teamB?.id) {
                         _tossWinner = null;
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      }
    );
  }

  void _createNewTeam(bool isTeamA) async {
     final nameController = TextEditingController();
     await showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('New Team Name'),
         content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Enter Name")),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
           TextButton(
             onPressed: () async {
               if (nameController.text.isNotEmpty) {
                 Navigator.pop(context);
                 final newTeam = await ref.read(scoringRepositoryProvider).createTeam(nameController.text);
                 setState(() {
                   if (isTeamA) _teamA = newTeam; else _teamB = newTeam;
                 });
               }
             },
             child: const Text('Create'),
           )
         ],
       )
     );
  }
  
  Future<void> _startMatch() async {
    if (_teamA == null || _teamB == null || _tossWinner == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select teams and toss result')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final match = await ref.read(scoringRepositoryProvider).createMatch(
        teamAId: _teamA!.id,
        teamBId: _teamB!.id,
        overs: int.tryParse(_oversController.text) ?? 20,
        ground: _groundController.text,
        tossWinnerId: _tossWinner!.id,
        tossDecision: _tossDecision,
      );
      
      if (mounted) {
        // TODO: Navigate to Scoring Screen with matchId
        context.push('/scoring/${match.id}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start a Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader('Teams'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTeamCard(_teamA, true)),
                 const Padding(
                   padding: EdgeInsets.symmetric(horizontal: 8.0),
                   child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                 ),
                Expanded(child: _buildTeamCard(_teamB, false)),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_teamA != null && _teamB != null) ...[
               _buildSectionHeader('Toss'),
               const SizedBox(height: 16),
               Card(
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Who won the toss?'),
                       Wrap(
                         spacing: 12,
                         children: [
                           ChoiceChip(
                             label: Text(_teamA!.name),
                             selected: _tossWinner?.id == _teamA!.id,
                             onSelected: (val) => setState(() => _tossWinner = val ? _teamA : null),
                           ),
                           ChoiceChip(
                             label: Text(_teamB!.name),
                             selected: _tossWinner?.id == _teamB!.id,
                             onSelected: (val) => setState(() => _tossWinner = val ? _teamB : null),
                           ),
                         ],
                       ),
                       const SizedBox(height: 16),
                        const Text('Decision?'),
                       Wrap(
                         spacing: 12,
                         children: [
                           ChoiceChip(
                             label: const Text('Bat'),
                             selected: _tossDecision == 'Bat',
                             onSelected: (val) => setState(() => _tossDecision = 'Bat'),
                           ),
                           ChoiceChip(
                             label: const Text('Bowl'),
                             selected: _tossDecision == 'Bowl',
                             onSelected: (val) => setState(() => _tossDecision = 'Bowl'),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 24),
            ],

            _buildSectionHeader('Match Details'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oversController,
              decoration: const InputDecoration(
                labelText: 'Overs',
                hintText: 'e.g. 20',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _groundController,
              decoration: const InputDecoration(
                labelText: 'Ground / Location',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Start Scoring', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4, 
          height: 24, 
          color: AppColors.primary, 
          margin: const EdgeInsets.only(right: 8)
        ),
        Text(
          title, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _buildTeamCard(Team? team, bool isTeamA) {
    return GestureDetector(
      onTap: () => _pickTeam(isTeamA),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: team?.logoUrl != null ? NetworkImage(team!.logoUrl!) : null,
                backgroundColor: Colors.grey.shade300,
                child: team == null ? const Icon(Icons.add, color: Colors.grey) : (team.logoUrl == null ? Text(team.name[0]) : null),
              ),
              const SizedBox(height: 8),
              Text(team?.name ?? 'Select Team', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
