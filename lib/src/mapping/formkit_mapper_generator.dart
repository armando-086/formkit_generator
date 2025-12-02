// ignore_for_file: depend_on_referenced_packages, unnecessary_import
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:formkit_generator/src/utils/field_info.dart';
import 'package:formkit_generator/src/utils/get_vo_info.dart';
import 'package:formkit_generator/src/utils/formkit_mapper_checker.dart';
import 'package:source_gen/source_gen.dart';

class FormKitMapperGenerator extends Generator {
  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    bool any = false;

    for (final element in library.classes) {
      if (!formkitMapperChecker.hasAnnotationOf(element)) continue;
      any = true;
      final generated = await _generateFor(element, buildStep);
      if (generated != null) {
        buffer.writeln(generated);
      }
    }

    return any ? buffer.toString() : null;
  }

  Future<String?> _generateFor(
    ClassElement outputClass,
    BuildStep buildStep,
  ) async {
    print('FormKitMapperGenerator invoked for ${buildStep.inputId}');

    final String? outputClassName = outputClass.name;
    final String generatedConfigName = '\$${outputClassName}FormConfig';
    final String generatedMapperName = '_${outputClassName}Mapper';
    final String generatedAccessName = '_${outputClassName}FormKitAccess';

    final String mapperContract = 'IFormMapper<$outputClassName>';
    final String accessContract = 'IFormKitAccess<$outputClassName>';

    final fields = outputClass.fields
        .where((f) => !f.isStatic && !f.isPrivate && !f.isSynthetic)
        .toList();

    if (fields.isEmpty) {
      throw InvalidGenerationSourceError(
        'Class $outputClassName must have fields to map.',
        element: outputClass,
      );
    }

    final buffer = StringBuffer();

    // --------------------------------------------------------------
    // HEADERS
    // --------------------------------------------------------------

    buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
    buffer.writeln(
      "// ignore_for_file: depend_on_referenced_packages, unnecessary_import",
    );
    buffer.writeln("import 'package:flutter/widgets.dart';");
    buffer.writeln("import 'package:formkit/formkit.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/contracts/icontroller_factory.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/contracts/iformkit_access.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/field_controller.dart';");

    // Importar entidad original
    final packageName = buildStep.inputId.package;
    final inputPath = buildStep.inputId.path;
    final relativePath =
        inputPath.startsWith('lib/') ? inputPath.substring(4) : inputPath;

    buffer.writeln("import 'package:$packageName/$relativePath';");
    buffer.writeln("");

    // --------------------------------------------------------------
    // 1. CONFIG
    // --------------------------------------------------------------

    buffer.writeln(
        '/// Configuración de formulario generada para $outputClassName');
    buffer.writeln(
        'class $generatedConfigName implements IFormConfig<$outputClassName> {');
    buffer.writeln('  const $generatedConfigName();');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln("  String get name => '${outputClassName?.toLowerCase()}';");
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, IFormSchema> get fields => {');

    for (final field in fields) {
      final fieldName = field.name;
      final FieldInfo info = getVoInfo(field);

      final String converter;
      final String voType = info.voType;
      final String primitiveType = info.primitiveType;

      if (info.isValueObject) {
        converter =
            'ValueObjectConverter<$primitiveType, $voType>((p) => $voType(p))';
      } else {
        converter = 'DefaultValueConverter<$voType>()';
      }

      buffer.writeln("    '$fieldName': FieldConfig<$primitiveType, $voType>(");
      buffer.writeln("      name: '$fieldName',");
      buffer.writeln("      valueConverter: $converter,");
      buffer.writeln(
          "      initialValue: rawValue['$fieldName'] as $primitiveType,");
      buffer.writeln('    ),');
    }

    buffer.writeln('  };');
    buffer.writeln('}');
    buffer.writeln('');

    // --------------------------------------------------------------
    // 2. MAPPER
    // --------------------------------------------------------------

    buffer.writeln('/// Mapper generado para $outputClassName');
    buffer.writeln('class $generatedMapperName implements $mapperContract {');
    buffer.writeln('  const $generatedMapperName();');
    buffer.writeln('');

    buffer.writeln('  @override');
    buffer.writeln('  $outputClassName map(Map<String, dynamic> rawValue) {');
    buffer.writeln('    return $outputClassName(');

    for (final field in fields) {
      final name = field.name;
      final info = getVoInfo(field);

      final raw = "rawValue['$name']";
      final primitive = info.primitiveType;

      final String value = (info.isValueObject)
          ? '${info.voType}($raw as $primitive)'
          : '$raw as $primitive';

      buffer.writeln('      $name: $value,');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    // --------------------------------------------------------------
    // 3. ACCESS
    // --------------------------------------------------------------

    buffer.writeln('/// Acceso generado para $outputClassName');
    buffer.writeln('class $generatedAccessName implements $accessContract {');
    buffer.writeln('  final IControllerFactory _controllerFactory;');
    buffer.writeln('  $generatedAccessName(this._controllerFactory);');
    buffer.writeln('');

    buffer.writeln('  @override');
    buffer.writeln(
        '  GlobalKey<FormState> get formKey => _controllerFactory.formKey;');
    buffer.writeln('');

    for (final field in fields) {
      final name = field.name;
      final info = getVoInfo(field);

      final ctype = 'FieldController<${info.primitiveType}, ${info.voType}>';

      buffer.writeln('  $ctype get $name {');
      buffer.writeln(
          "    final controller = _controllerFactory.getController('$name');");
      buffer.writeln('    if (controller is! $ctype) {');
      buffer.writeln(
          "      throw StateError('Controller $name is not type $ctype');");
      buffer.writeln('    }');
      buffer.writeln('    return controller;');
      buffer.writeln('  }');
      buffer.writeln('');
    }

    buffer.writeln('  @override');
    buffer.writeln('  Map<String, IFieldController> get allControllers {');
    buffer
        .writeln('    return _controllerFactory.binders.map((key, binder) => ');
    buffer.writeln(
        "      MapEntry(key, _controllerFactory.getController(key)!),");
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  @override');
    buffer.writeln(
        '  IFieldController<P, V>? getController<P, V>(String fieldName) {');
    buffer
        .writeln('    final c = _controllerFactory.getController(fieldName);');
    buffer.writeln('    return c is IFieldController<P, V> ? c : null;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    // --------------------------------------------------------------
    // 4. .formkit_access_ref
    // --------------------------------------------------------------

    final refId = buildStep.inputId
        .changeExtension('.formkit_register_ref'); 

    final ref = StringBuffer();
    ref.writeln('FormKitAccess:$generatedAccessName');
    ref.writeln('Entity:$outputClassName');
    ref.writeln('Path:${relativePath}');

    await buildStep.writeAsString(refId, ref.toString());

    return buffer.toString();
  }
}
