import 'package:build/build.dart';

class FormKitAutoRegisterCollector implements PostProcessBuilder {
  //. Constante estática con la ruta del archivo final, necesaria para el Finalizer.
  static const outputFilePath = 'lib/formkit_auto_register.dart';

  @override
  Iterable<String> get inputExtensions => const ['.formkit_register_ref'];

  String get outputExtension => '.formkit_register_collector';

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    //. Este PostProcessBuilder solo asegura que los archivos .formkit_access_ref sean
    //. consumidos y que la constante de ruta sea accesible para el finalizador.
  }
}