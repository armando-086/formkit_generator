// ignore: depend_on_referenced_packages
import 'package:build/build.dart';
import 'package:formkit_generator/builder/formkit_auto_register_collector.dart';

PostProcessBuilder formKitAutoRegisterBuilder(BuilderOptions options) {
  return FormKitAutoRegisterCollector();
}