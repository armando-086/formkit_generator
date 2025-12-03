// ignore: depend_on_referenced_packages
import 'package:build/build.dart';
import 'package:formkit_generator/builder/formkit_auto_register_finalizer.dart';

Builder formKitAutoRegisterFinalizerBuilder(BuilderOptions options) {
  return FormKitAutoRegisterFinalizer(options);
}
