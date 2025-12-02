import 'package:build/build.dart';
import 'package:formkit_generator/src/generator/formkit_auto_register_collector.dart'; 

PostProcessBuilder formkitAutoRegisterBuilder(BuilderOptions options) {
  return FormKitAutoRegisterCollector();
}