import 'package:build/build.dart';
import 'package:formkit_generator/src/build/formkit_auto_register_finalizer.dart'; 

Builder formkitAutoRegisterFinalizerBuilder(BuilderOptions options) {
  return FormKitAutoRegisterFinalizer(options);
}
