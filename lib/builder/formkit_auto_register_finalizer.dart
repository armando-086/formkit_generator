// ignore_for_file: depend_on_referenced_packages
import 'package:build/build.dart';
import 'package:formkit_generator/builder/formkit_auto_register_collector.dart';
import 'package:glob/glob.dart';

class FormKitAutoRegisterFinalizer extends Builder {
  final BuilderOptions options;

  FormKitAutoRegisterFinalizer(this.options);

  // Definimos la única salida que este builder producirá, dentro del paquete 'formkit'
  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': [FormKitAutoRegisterCollector.outputFilePath],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // 1. Recoger todos los archivos de referencia (`.formkit_access_ref`)
    final accessRefAssets = buildStep.findAssets(
      Glob('**.formkit_access_ref'),
    );

    final List<Map<String, String>> accessClasses = [];

    // 2. Leer los nombres de las clases de acceso y sus entidades
    await for (final assetId in accessRefAssets) {
      if (await buildStep.canRead(assetId)) {
        try {
          final content = await buildStep.readAsString(assetId);
          
          final classNameMatch = RegExp(r'FormKitAccess:(\w+)').firstMatch(content);
          final entityNameMatch = RegExp(r'Entity:(\w+)').firstMatch(content);
          final pathMatch = RegExp(r'Path:(.+)').firstMatch(content);
          
          if (classNameMatch != null && entityNameMatch != null && pathMatch != null) {
            final className = classNameMatch.group(1)!;
            final entityName = entityNameMatch.group(1)!;
            String importPath = pathMatch.group(1)!;
            
            // Usamos el nombre real del paquete del AssetId de referencia.
            final packageName = assetId.package;

            // Creamos la importación dinámica
            importPath = 'package:$packageName/$importPath';

            accessClasses.add({
              'className': className,
              'entityName': entityName,
              'importPath': importPath,
            });
          }
        } catch (e) {
          log.severe('Error reading access reference from ${assetId.path}: $e');
        }
      }
    }

    if (accessClasses.isEmpty) {
      return;
    }

    // 3. Generar el contenido del archivo FormKitAutoRegister.dart
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: depend_on_referenced_packages, unnecessary_import');
    buffer.writeln('');
    
    // Importaciones necesarias
    buffer.writeln("import 'package:formkit/src/flutter/core/contracts/iformkit_access.dart';");
    buffer.writeln("import 'package:formkit/src/flutter/core/contracts/icontroller_factory.dart';");

    final imports = accessClasses.map((c) => c['importPath']).toSet();
    for (final importPath in imports) {
      buffer.writeln("import '$importPath';");
    }

    buffer.writeln('');
    
    // Definición de la función de registro genérica (DI Agnosticismo)
    buffer.writeln('typedef FormKitAccessRegister<TDI> = void Function<TEntity>({');
    buffer.writeln(' required TDI di,');
    buffer.writeln(' required IFormKitAccess<TEntity> Function(IControllerFactory) factory,');
    buffer.writeln('});');
    buffer.writeln('');

    buffer.writeln('/// Clase generada que contiene la lógica de registro para todas las clases [IFormKitAccess].');
    buffer.writeln('class FormKitAutoRegister {');
    buffer.writeln('  FormKitAutoRegister._();');
    buffer.writeln('');

    buffer.writeln('  static void registerAll<TDI>({');
    buffer.writeln('    required TDI di,');
    buffer.writeln('    required FormKitAccessRegister<TDI> registerFn,');
    buffer.writeln('  }) {');
    
    // 4. Generar la llamada a `registerFn` para cada clase de acceso
    for (final access in accessClasses) {
      final className = access['className']!;
      final entityName = access['entityName']!;
      
      // Creamos la factoría específica para cada clase generada
      buffer.writeln('    registerFn<$entityName>(di: di, factory: (factory) => $className(factory));');
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    // 5. Escribir el archivo final en el paquete `formkit`
    final outputId = AssetId(
      'formkit', 
      FormKitAutoRegisterCollector.outputFilePath,
    );

    await buildStep.writeAsString(outputId, buffer.toString());
  }
}