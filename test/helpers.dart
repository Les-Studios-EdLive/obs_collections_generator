
import 'package:args/command_runner.dart';

CommandRunner loadCommandRunner(Command command) => CommandRunner("obs_collections_generator_test", "")
  ..addCommand(command);