enum RegistrationOperation {
  authCreate('AUTH_CREATE'),
  userDocumentCreate('USER_DOC_CREATE'),
  userDocumentUpdate('USER_DOC_UPDATE'),
  profileCreate('PROFILE_CREATE'),
  profileUpdate('PROFILE_UPDATE'),
  appCheck('APP_CHECK'),
  network('NETWORK'),
  unknown('UNKNOWN');

  const RegistrationOperation(this.code);

  final String code;
}
