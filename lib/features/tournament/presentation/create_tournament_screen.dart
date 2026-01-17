import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/fixture_generator.dart';
import '../data/tournament_repository.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Info
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _format = "T20"; // T20, ODI, Test

  // Step 2: Teams
  List<Map<String, dynamic>> _allTeams = [];
  final Set<String> _selectedTeamIds = {};
  bool _teamsLoading = true;

  // Step 3: Settings
  bool _autoGenerateFixtures = true;
  bool _enforceRestDays = true;
  int _matchesPerDay = 2;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    // Fetch teams using existing repo or Supabase client
    // For demo, we assume we can get a list of teams.
    // In strict architecture, use a Provider.
    final repo = ref.read(tournamentRepositoryProvider);
    // Assuming repo has a method or we access client directly for now to be quick
    // Ideally update repo to fetchAllTeams()

    // TEMPORARY: Direct call for speed, consistent with other screens
    try {
      final res = await ref.read(tournamentRepositoryProvider).getAllTeams();
      if (mounted) {
        setState(() {
          _allTeams = res;
          _teamsLoading = false;
        });
      }
    } catch (e) {
      // fallback or error
      if (mounted) setState(() => _teamsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Tournament"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Custom Stepper Header
          _buildStepIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1Info(),
                  _buildStep2Teams(),
                  _buildStep3Settings(),
                  _buildStep4Review(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepIcon(0, "Info"),
          _stepLine(0),
          _stepIcon(1, "Teams"),
          _stepLine(1),
          _stepIcon(2, "Rules"),
          _stepLine(2),
          _stepIcon(3, "Review"),
        ],
      ),
    );
  }

  Widget _stepIcon(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? AppColors.primary : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  "${step + 1}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int step) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      color: _currentStep > step ? AppColors.primary : Colors.grey.shade300,
    );
  }

  // --- STEPS ---

  Widget _buildStep1Info() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: "Tournament Name",
            hintText: "Ex: Mumbai Premier League 2026",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.emoji_events_outlined),
          ),
          validator: (val) =>
              (val == null || val.length < 3) ? "Enter valid name" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _venueController,
          decoration: const InputDecoration(
            labelText: "Default Venue",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.stadium_outlined),
          ),
          validator: (val) =>
              (val == null || val.isEmpty) ? "Venue required" : null,
        ),
        const SizedBox(height: 16),
        // Format
        const Text("Format", style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: ["T20", "ODI", "Test", "10-Over"]
              .map(
                (f) => ChoiceChip(
                  label: Text(f),
                  selected: _format == f,
                  onSelected: (val) => setState(() => _format = f),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        // Dates
        Row(
          children: [
            Expanded(
              child: _datePicker(
                "Start Date",
                _startDate,
                (d) => setState(() => _startDate = d),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _datePicker(
                "End Date",
                _endDate,
                (d) => setState(() => _endDate = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Duration: ${_endDate.difference(_startDate).inDays + 1} days",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime date, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text("${date.day}/${date.month}/${date.year}"),
      ),
    );
  }

  Widget _buildStep2Teams() {
    return _teamsLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Selected: ${_selectedTeamIds.length} Teams (Min 4)",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _allTeams.length,
                  itemBuilder: (ctx, i) {
                    final team = _allTeams[i];
                    final isSelected = _selectedTeamIds.contains(team['id']);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(team['name']),
                      secondary: CircleAvatar(
                        backgroundImage: team['logo_url'] != null
                            ? NetworkImage(team['logo_url'])
                            : null,
                        child: team['logo_url'] == null
                            ? const Icon(Icons.shield)
                            : null,
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
            ],
          );
  }

  Widget _buildStep3Settings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text("Auto-Generate Fixtures"),
          subtitle: const Text("Create Round-Robin schedule automatically"),
          value: _autoGenerateFixtures,
          onChanged: (v) => setState(() => _autoGenerateFixtures = v),
        ),
        if (_autoGenerateFixtures) ...[
          const Divider(),
          SwitchListTile(
            title: const Text("Enforce Rest Days"),
            subtitle: const Text("Prevent back-to-back matches for same team"),
            value: _enforceRestDays,
            onChanged: (v) => setState(() => _enforceRestDays = v),
          ),
          ListTile(
            title: const Text("Matches per Day"),
            trailing: DropdownButton<int>(
              value: _matchesPerDay,
              items: [1, 2, 3, 4]
                  .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                  .toList(),
              onChanged: (v) => setState(() => _matchesPerDay = v!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep4Review() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _reviewItem("Name", _nameController.text),
        _reviewItem("Format", _format),
        _reviewItem(
          "Dates",
          "${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}",
        ),
        _reviewItem("Teams", "${_selectedTeamIds.length} Participating"),
        const Divider(),
        const Text(
          "Summary",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          "This will create a new tournament and ${_autoGenerateFixtures ? 'generate' : 'prepare'} scheule. "
          "Verify all details before confirming.",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text("Back"),
            ),

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: _isLoading ? null : _handleNext,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_currentStep == 3 ? "Create Tournament" : "Next"),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (_endDate.isBefore(_startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End date must be after start date")),
        );
        return;
      }
    }
    if (_currentStep == 1) {
      if (_selectedTeamIds.length < 2) {
        // Allow 2 for now, ideally 4
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select at least 2 teams")),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      // 1. Create Tournament Record
      final repo = ref.read(tournamentRepositoryProvider);
      final tourId = await repo.createTournament(
        name: _nameController.text,
        venue: _venueController.text,
        format: _format,
        startDate: _startDate,
        endDate: _endDate,
        teamIds: _selectedTeamIds.toList(),
      );

      // 2. Generate Fixtures (if enabled)
      if (_autoGenerateFixtures) {
        final fixtures = FixtureGenerator.generateRoundRobin(
          teamIds: _selectedTeamIds.toList(),
          startDate: _startDate,
          tournamentId: tourId!,
          matchesPerDay: _matchesPerDay,
          allowBackToBack: !_enforceRestDays,
        );
        await repo.bulkCreateMatches(fixtures);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tournament Created Successfully! 🏆")),
        );
        Navigator.pop(context); // Return to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
