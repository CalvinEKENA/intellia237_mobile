enum IntelliaAuthMethod {
  phoneOtp,
  email,
  parentLinked,
  establishment,
  passkey,
}

extension IntelliaAuthMethodX on IntelliaAuthMethod {
  int get priority => switch (this) {
    IntelliaAuthMethod.phoneOtp => 1,
    IntelliaAuthMethod.email => 2,
    IntelliaAuthMethod.parentLinked => 3,
    IntelliaAuthMethod.establishment => 4,
    IntelliaAuthMethod.passkey => 5,
  };

  bool get isAvailableNow => switch (this) {
    IntelliaAuthMethod.email || IntelliaAuthMethod.parentLinked => true,
    IntelliaAuthMethod.phoneOtp ||
    IntelliaAuthMethod.establishment ||
    IntelliaAuthMethod.passkey => false,
  };
}
