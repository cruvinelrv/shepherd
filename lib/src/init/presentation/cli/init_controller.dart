import 'package:shepherd/src/init/presentation/cli/init/quick_init.dart';

class InitController {
  /// Sets up the standard project in the current folder (see [runQuickInit]).
  Future<int> handleInit({List<String> args = const []}) => runQuickInit(args);
}
