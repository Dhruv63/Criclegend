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
  ConsumerState<ScheduleMatchScreen> createState() =>
      _ScheduleMatchScreenState();
}

class _ScheduleMatchScreenState extends ConsumerState<ScheduleMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oversController = TextEditingController(text: '20');
  final _groundController = TextEditingController();
  final _notesController = TextEditingController();

  Team? _teamA;
  Team? _teamB;

  // Default to tomorrow, 10:00 AM
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  String _matchType = 'Friendly';
  String _matchFormat = 'T20';

  bool _isLoading = false;

  final List<String> _matchTypes = [
    'Friendly',
    'League',
    'Tournament',
    'Practice',
  ];
  final List<String> _matchFormats = [
    'T20',
    'ODI',
    'Test',
    '100-Ball',
    'Custom',
  ];

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
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                    title: const Text('Create New Team'),
                    onTap: () {
                      Navigator.pop(context);
                      _createNewTeam(isTeamA);
                    },
                  );
                }
                final team = teams[index];
                final bool isSelectedAlready =
                    (isTeamA && _teamB?.id == team.id) ||
                    (!isTeamA && _teamA?.id == team.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: team.logoUrl != null
                        ? NetworkImage(team.logoUrl!)
                        : null,
                    child: team.logoUrl == null ? Text(team.name[0]) : null,
                  ),
                  title: Text(team.name),
                  subtitle: Text('${team.players.length} players'),
                  enabled: !isSelectedAlready,
                  trailing: isSelectedAlready
                      ? const Icon(Icons.block, color: Colors.grey)
                      : null,
                  onTap: () {
                    setState(() {
                      if (isTeamA) {
                        _teamA = team;
                      } else {
                        _teamB = team;
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _createNewTeam(bool isTeamA) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Team Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final newTeam = await ref
                      .read(scoringRepositoryProvider)
                      .createTeam(nameController.text);
                  setState(() {
                    if (isTeamA) {
                      _teamA = newTeam;
                    } else {
                      _teamB = newTeam;
                    }
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating team: $e")),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 0),
      ), // Allow today
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (picked.isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot schedule match in the past!")),
        );
        return;
      }
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
      if (format == 'T20') {
        _oversController.text = '20';
      } else if (format == 'ODI')
        _oversController.text = '50';
      else if (format == '100-Ball')
        _oversController.text = '16.4';
      else if (format == 'Test')
        _oversController.text = '90';
    });
  }

  Future<void> _scheduleMatch() async {
    if (!_formKey.currentState!.validate()) return;

    // Strict Validation
    if (_teamA == null || _teamB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both teams'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_teamA!.id == _teamB!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teams must be different'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match date/time cannot be in the past!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(scoringRepositoryProvider)
          .createMatch(
            teamAId: _teamA!.id,
            teamBId: _teamB!.id,
            overs: int.tryParse(_oversController.text) ?? 20,
            ground: _groundController.text.isEmpty
                ? 'Unknown Ground'
                : _groundController.text,
            scheduledDate: scheduledDateTime,
            matchType: _matchType,
            matchFormat: _matchFormat,
            notes: _notesController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match Scheduled Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home'); // Or to upcoming matches tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionHeader('TEAMS', Icons.group_outlined),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTeamCard(_teamA, true)),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 40,
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(child: _buildTeamCard(_teamB, false)),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(
                'MATCH DETAILS',
                Icons.sports_cricket_outlined,
              ),
              const SizedBox(height: 16),

              // Format & Type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _matchFormat,
                      decoration: const InputDecoration(
                        labelText: 'Format',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_bulleted),
                      ),
                      items: _matchFormats
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (val) => _updateDefaultOvers(val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _matchType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _matchTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _matchType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Overs & Ground
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _oversController,
                      decoration: const InputDecoration(
                        labelText: 'Overs',
                        border: OutlineInputBorder(),
                        helperText: 'Standard: 20 or 50',
                        prefixIcon: Icon(Icons.history_toggle_off),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final overs = int.tryParse(value ?? '');
                        if (overs == null || overs <= 0 || overs > 200) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _groundController,
                      decoration: const InputDecoration(
                        labelText: 'Ground / Venue',
                        border: OutlineInputBorder(),
                        helperText: 'e.g., Wankhede Stadium',
                        prefixIcon: Icon(Icons.stadium_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
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
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('EEE, d MMM y').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
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
                decoration: const InputDecoration(
                  labelText: 'Match Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _scheduleMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isLoading ? 0 : 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Scheduling...'),
                          ],
                        )
                      : const Text(
                          'SCHEDULE MATCH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const Expanded(child: Divider(indent: 12, height: 30, thickness: 1)),
      ],
    );
  }

  Widget _buildTeamCard(Team? team, bool isTeamA) {
    bool hasTeam = team != null;
    return GestureDetector(
      onTap: () => _pickTeam(isTeamA),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTeam
                ? AppColors.primary.withOpacity(0.5)
                : Colors.grey.shade300,
            width: hasTeam ? 2 : 1,
          ),
          boxShadow: [
            if (hasTeam)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: team?.logoUrl != null
                  ? NetworkImage(team!.logoUrl!)
                  : null,
              backgroundColor: hasTeam
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.shade100,
              child: !hasTeam
                  ? const Icon(Icons.add, color: Colors.grey, size: 30)
                  : (team.logoUrl == null
                        ? Text(
                            team.name[0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                team?.name ?? (isTeamA ? 'Team A' : 'Team B'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasTeam ? Colors.black : Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasTeam)
              Text(
                '${team.players.length} Players',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}
