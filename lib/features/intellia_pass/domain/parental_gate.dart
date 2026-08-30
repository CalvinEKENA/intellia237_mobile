enum ParentalGateMethod { biometric, parentPin, reauthentication }

enum ParentalOperation {
  addLearner,
  editLearner,
  viewHouseholdSettings,
  changeSubscription,
}

class ParentalGateRequest {
  const ParentalGateRequest({required this.operation, required this.method});

  final ParentalOperation operation;
  final ParentalGateMethod method;
}

abstract interface class ParentalGate {
  /// This local proof improves shared-device ergonomics but never replaces
  /// the authoritative server-side permission check for the operation.
  Future<bool> verifyLocally(ParentalGateRequest request);
}

class ParentSensitiveAccess {
  const ParentSensitiveAccess(this.gate);

  final ParentalGate gate;

  Future<bool> request({
    required ParentalOperation operation,
    required ParentalGateMethod method,
  }) => gate.verifyLocally(
    ParentalGateRequest(operation: operation, method: method),
  );
}
