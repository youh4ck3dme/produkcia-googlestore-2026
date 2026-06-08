import 'package:bizagent/core/config/play_release_scope.dart';

/// Demo mode je v Play MVP zámerne vypnutý — testy aktivácie preskočíme.
String? get skipDemoMutationTests =>
    PlayReleaseScope.playMvp ? 'Demo mode disabled in Play MVP build' : null;
