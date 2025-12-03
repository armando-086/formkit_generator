// ignore_for_file: depend_on_referenced_packages
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:formkit_generator/type_checker/formkit_target_checker.dart';

class FormKitAccessRefBuilder implements Builder {
  const FormKitAccessRefBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.formkit_access_ref'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    //. Solo procesamos archivos .dart
    if (!buildStep.inputId.path.endsWith('.dart')) {
      return;
    }

    final resolver = buildStep.resolver;
    //. Verifica si es parte de una biblioteca Dart (esencial para el análisis)
    if (!await resolver.isLibrary(buildStep.inputId)) {
      return;
    }

    final unit = await resolver.compilationUnitFor(buildStep.inputId);
    final topLevelDeclarations = unit.declarations;
    
    //. Buscar todas las clases anotadas con FormKitTarget
    for (final element in topLevelDeclarations) {
      if (element is ClassElement) {

        final ClassElement outputClass = element as ClassElement;
        
        if (formKitTargetChecker.hasAnnotationOfExact(outputClass)) {
          
          final String? outputClassName = outputClass.name;
          final String generatedAccessName = '${outputClassName}FormKit';
          
          final inputPath = buildStep.inputId.path;
          final relativePath = inputPath.startsWith('lib/')
              ? inputPath.substring(4)
              : inputPath;

          //. Contenido del archivo .formkit_access_ref
          final ref = StringBuffer();
          ref.writeln('FormKitAccess:$generatedAccessName');
          ref.writeln('Entity:$outputClassName');
          ref.writeln('Path:$relativePath');

          //. Escribir el nuevo Asset (Archivo .formkit_access_ref)
          final outputId = buildStep.inputId.changeExtension('.formkit_access_ref');
          await buildStep.writeAsString(outputId, ref.toString());
          
          //. Ya encontramos la clase, podemos salir del bucle.
          return; 
        }
      }
    }
  }
}