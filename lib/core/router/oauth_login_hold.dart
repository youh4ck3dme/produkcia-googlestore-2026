/// Web OAuth PKCE: while `?code=` is present and session is not ready yet,
/// keep the user on `/login` so the callback handler can exchange the code.
bool shouldHoldLoginForOAuthCode({
  required bool isWeb,
  required Map<String, String> queryParameters,
  required bool isLoggedIn,
}) {
  return isWeb && queryParameters.containsKey('code') && !isLoggedIn;
}
