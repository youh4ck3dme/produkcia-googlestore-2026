enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;

  const AuthState._(this.status);

  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.authenticated() : this._(AuthStatus.authenticated);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthed => status == AuthStatus.authenticated;
}
