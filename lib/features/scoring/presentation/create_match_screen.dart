import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../scoring/data/scoring_provider.dart';
import '../../scoring/domain/team_model.dart';

class ScheduleMatchScreen extends ConsumerStatefulWidget {
  const ScheduleMatchScreen({super.key});

  @override
  ConsumerState<ScheduleMatchScreen> createState() => _ScheduleMatchScreenState();
}

class _ScheduleMatchScreenState extends ConsumerState<ScheduleMatchScreen> {
  final _oversController = TextEditingController(text: '20');
  final _groundController = TextEditingController();
  final _notesController = TextEditingController();
  
  Team? _teamA;
  Team? _teamB;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _matchType = 'Friendly';
  String _matchFormat = 'T20';
  
  bool _isLoading = false;

  final List<String> _matchTypes = ['Friendly', 'League', 'Tournament', 'Practice'];
  final List<String> _matchFormats = ['T20', 'ODI', 'Test', '100-Ball', 'Custom'];

  @override
  void dispose() {
    _oversController.dispose();
    _groundController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
                     onTap: () {
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
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _updateDefaultOvers(String format) {
    setState(() {
      _matchFormat = format;
      if (format == 'T20') _oversController.text = '20';
      else if (format == 'ODI') _oversController.text = '50';
      else if (format == '100-Ball') _oversController.text = '16.4'; // Approx or handle balls separately
      else if (format == 'Test') _oversController.text = '90';
    });
  }

  Future<void> _scheduleMatch() async {
    if (_teamA == null || _teamB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both teams')));
      return;
    }
    if (_teamA!.id == _teamB!.id) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teams must be different')));
       return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Combine Date and Time
      final scheduledDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute
      );

      await ref.read(scoringRepositoryProvider).createMatch(
        teamAId: _teamA!.id,
        teamBId: _teamB!.id,
        overs: int.tryParse(_oversController.text) ?? 20,
        ground: _groundController.text.isEmpty ? 'Unknown Ground' : _groundController.text,
        scheduledDate: scheduledDateTime,
        matchType: _matchType,
        matchFormat: _matchFormat,
        notes: _notesController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match Scheduled Successfully!')));
        context.go('/home'); // Or to upcoming matches tab
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
      appBar: AppBar(title: const Text('Schedule Match')),
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
                   child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 ),
                Expanded(child: _buildTeamCard(_teamB, false)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Match Details'),
            const SizedBox(height: 16),
            
            // Format & Type
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _matchFormat,
                    decoration: const InputDecoration(labelText: 'Format', border: OutlineInputBorder()),
                    items: _matchFormats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) => _updateDefaultOvers(val!),
                  ),
                ),
                const SizedBox(width: 12),
                 Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _matchType,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: _matchTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _matchType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overs & Ground
            Row(
              children: [
                 Expanded(
                  child: TextFormField(
                    controller: _oversController,
                    decoration: const InputDecoration(labelText: 'Overs', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _groundController,
                    decoration: const InputDecoration(labelText: 'Ground / Venue', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
             const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(DateFormat('EEE, d MMM y').format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Notes
             TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Match Notes (Optional)', border: OutlineInputBorder(), alignLabelWithHint: true),
              maxLines: 2,
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _scheduleMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Schedule Match', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Container(width: 4, height: 24, color: AppColors.primary, margin: const EdgeInsets.only(right: 8)),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTeamCard(Team? team, bool isTeamA) {
    return GestureDetector(
      onTap: () => _pickTeam(isTeamA),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: team?.logoUrl != null ? NetworkImage(team!.logoUrl!) : null,
                backgroundColor: Colors.grey.shade100,
                child: team == null ? const Icon(Icons.add, color: Colors.grey) : (team.logoUrl == null ? Text(team.name[0]) : null),
              ),
              const SizedBox(height: 8),
              Text(team?.name ?? 'Select Team', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
