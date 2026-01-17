import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/data/supabase_service.dart';
import '../domain/ball_model.dart';
import 'package:flutter/foundation.dart';

class ScoringQueueService extends ChangeNotifier {
  // Singleton pattern
  static final ScoringQueueService _instance = ScoringQueueService._internal();
  factory ScoringQueueService() => _instance;
  ScoringQueueService._internal();

  List<BallModel> _queue = [];
  bool _isProcessing = false;

  // Public Getter for UI to show "Syncing..." status
  int get queueLength => _queue.length;
  bool get isSyncing => _isProcessing;

  // Initialize and load any pending events from disk
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('scoring_queue');
    if (stored != null) {
      try {
        final List decoded = jsonDecode(stored);
        _queue = decoded.map((e) => BallModel.fromJson(e)).toList();
        print("ScoringQueue: Loaded ${_queue.length} pending events.");
        if (_queue.isNotEmpty) {
          _processQueue(); // Try to clear them now
        }
      } catch (e) {
        print("ScoringQueue: Error loading queue: $e");
      }
    }
  }

  // Add event to queue and trigger process
  Future<void> enqueue(BallModel ball) async {
    _queue.add(ball);
    notifyListeners(); // Update UI red dot?
    await _persist();
    _processQueue();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    // Use toQueueJson to include snapshots
    final encoded = jsonEncode(_queue.map((e) => e.toQueueJson()).toList());
    await prefs.setString('scoring_queue', encoded);
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final event = _queue.first;

      // VALIDATION: Check for empty UUIDs which crash Supabase
      if (event.strikerId.isEmpty ||
          event.bowlerId.isEmpty ||
          event.inningId.isEmpty) {
        print(
          "ScoringQueue: DISCARDING invalid event (Empty ID): ${event.toJson()}",
        );
        _queue.removeAt(0);
        await _persist();
        continue;
      }

      try {
        print(
          "ScoringQueue: Processing Ball ${event.ballNumber} (Score: ${event.matchTotalRuns}/${event.matchWickets})",
        );

        // Use the snapshot data from the event itself
        await SupabaseService.recordBallEvent(
          ball: event,
          newTotalRuns: event.matchTotalRuns,
          newOvers: event.matchOvers,
          newWickets: event.matchWickets,
          currentStrikerId: event.strikerId,
          currentNonStrikerId: event.nonStrikerId,
          currentBowlerId: event.bowlerId,
        );

        _queue.removeAt(0);
        await _persist();
        notifyListeners();
      } catch (e) {
        print("ScoringQueue: Failed to sync. Retrying in 5s... Error: $e");
        await Future.delayed(const Duration(seconds: 5));
        // Simple retry loop: If it fails, we wait 5s and loop again (because queue is not empty).
        // If the app is closed, 'init()' will pick it up next time.
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  Future<bool> undoLastBall() async {
    if (_queue.isNotEmpty) {
      _queue.removeLast();
      await _persist();
      notifyListeners();
      return true;
    }
    return false;
  }
}
