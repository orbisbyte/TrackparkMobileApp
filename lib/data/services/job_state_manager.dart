import 'package:get/get.dart';

/// Job step tracking enum
enum JobStep {
  track, // Tracking to location
  form, // Filling form
  complete, // Completing job
}

/// Job phase type
enum JobPhase {
  pickup, // ontheway - going to pickup location
  delivery, // started - going to delivery/parking location
}

/// State data for a job phase
class JobPhaseState {
  final String jobId;
  final JobPhase phase;
  JobStep currentStep;
  bool isWithinRadius;
  bool isTimerActive;
  int remainingSeconds;
  bool isTimerExpired;
  String? timeExceededAt; // 'start' or 'end'
  bool
  didClickBeforeTimeExceed; // Whether driver clicked button before timer expired

  JobPhaseState({
    required this.jobId,
    required this.phase,
    this.currentStep = JobStep.track,
    this.isWithinRadius = false,
    this.isTimerActive = false,
    this.remainingSeconds = 300, // 5 minutes default
    this.isTimerExpired = false,
    this.timeExceededAt,
    this.didClickBeforeTimeExceed = false,
  });

  /// Create a copy with updated values
  JobPhaseState copyWith({
    JobStep? currentStep,
    bool? isWithinRadius,
    bool? isTimerActive,
    int? remainingSeconds,
    bool? isTimerExpired,
    String? timeExceededAt,
    bool? didClickBeforeTimeExceed,
  }) {
    return JobPhaseState(
      jobId: jobId,
      phase: phase,
      currentStep: currentStep ?? this.currentStep,
      isWithinRadius: isWithinRadius ?? this.isWithinRadius,
      isTimerActive: isTimerActive ?? this.isTimerActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isTimerExpired: isTimerExpired ?? this.isTimerExpired,
      timeExceededAt: timeExceededAt ?? this.timeExceededAt,
      didClickBeforeTimeExceed:
          didClickBeforeTimeExceed ?? this.didClickBeforeTimeExceed,
    );
  }

  /// Reset all state to initial values
  void reset() {
    currentStep = JobStep.track;
    isWithinRadius = false;
    isTimerActive = false;
    remainingSeconds = 300;
    isTimerExpired = false;
    timeExceededAt = null;
    didClickBeforeTimeExceed = false;
  }
}

/// Service to manage job state across different modules and phases
/// This persists even when controllers are disposed
class JobStateManager extends GetxService {
  // Store state for each job phase
  // Key format: "jobId_phase" e.g., "123_pickup" or "123_delivery"
  final Map<String, Rx<JobPhaseState>> _jobStates = {};

  /// Get or create state for a job phase
  Rx<JobPhaseState> getJobPhaseState(String jobId, JobPhase phase) {
    final key = _getKey(jobId, phase);

    if (!_jobStates.containsKey(key)) {
      _jobStates[key] = JobPhaseState(jobId: jobId, phase: phase).obs;
    }

    return _jobStates[key]!;
  }

  /// Update current step for a job phase
  void updateCurrentStep(String jobId, JobPhase phase, JobStep step) {
    final state = getJobPhaseState(jobId, phase);
    state.value = state.value.copyWith(currentStep: step);
  }

  /// Update timer state
  void updateTimerState({
    required String jobId,
    required JobPhase phase,
    bool? isWithinRadius,
    bool? isTimerActive,
    int? remainingSeconds,
    bool? isTimerExpired,
  }) {
    final state = getJobPhaseState(jobId, phase);
    state.value = state.value.copyWith(
      isWithinRadius: isWithinRadius,
      isTimerActive: isTimerActive,
      remainingSeconds: remainingSeconds,
      isTimerExpired: isTimerExpired,
    );
  }

  /// Mark time exceeded
  void markTimeExceeded(String jobId, JobPhase phase, String exceededAt) {
    final state = getJobPhaseState(jobId, phase);
    state.value = state.value.copyWith(
      isTimerExpired: true,
      isTimerActive: false,
      timeExceededAt: exceededAt,
    );
  }

  /// Mark that driver clicked before time exceeded
  void markClickedBeforeTimeExceed(String jobId, JobPhase phase) {
    final state = getJobPhaseState(jobId, phase);
    state.value = state.value.copyWith(
      didClickBeforeTimeExceed: true,
      isTimerActive: false,
    );
  }

  /// Reset state for a specific job phase
  void resetJobPhase(String jobId, JobPhase phase) {
    final key = _getKey(jobId, phase);
    if (_jobStates.containsKey(key)) {
      _jobStates[key]!.value.reset();
    }
  }

  /// Reset all states for a job (both phases)
  void resetJob(String jobId) {
    resetJobPhase(jobId, JobPhase.pickup);
    resetJobPhase(jobId, JobPhase.delivery);
  }

  /// Clear all states (useful for logout or cleanup)
  void clearAll() {
    _jobStates.clear();
  }

  /// Remove state for a specific job phase
  void removeJobPhase(String jobId, JobPhase phase) {
    final key = _getKey(jobId, phase);
    _jobStates.remove(key);
  }

  /// Remove all states for a job
  void removeJob(String jobId) {
    removeJobPhase(jobId, JobPhase.pickup);
    removeJobPhase(jobId, JobPhase.delivery);
  }

  /// Get current step for a job phase
  JobStep getCurrentStep(String jobId, JobPhase phase) {
    return getJobPhaseState(jobId, phase).value.currentStep;
  }

  /// Check if timer is expired for a job phase
  bool isTimerExpired(String jobId, JobPhase phase) {
    return getJobPhaseState(jobId, phase).value.isTimerExpired;
  }

  /// Check if driver clicked before time exceeded
  bool didClickBeforeTimeExceed(String jobId, JobPhase phase) {
    return getJobPhaseState(jobId, phase).value.didClickBeforeTimeExceed;
  }

  /// Get time exceeded at value
  String? getTimeExceededAt(String jobId, JobPhase phase) {
    return getJobPhaseState(jobId, phase).value.timeExceededAt;
  }

  /// Generate key for job phase
  String _getKey(String jobId, JobPhase phase) {
    return '${jobId}_${phase.name}';
  }
}
