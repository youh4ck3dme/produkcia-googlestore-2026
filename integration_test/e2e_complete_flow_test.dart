import 'package:integration_test/integration_test.dart';

import '../test/integration_mvp/e2e_complete_flow_test.dart' as mvp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  mvp.main();
}
