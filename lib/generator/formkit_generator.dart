// ignore_for_file: depend_on_referenced_packages, unnecessary_import
import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:formkit/formkit.dart';
import 'package:formkit_generator/utils/field_info.dart';
import 'package:formkit_generator/utils/get_vo_info.dart';
import 'package:source_gen/source_gen.dart';

/// Generador principal de FormKit.
class FormKitGenerator extends GeneratorForAnnotation<FormKitTarget> {
  const FormKitGenerator();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // 1. Validación y Extracción de Clases
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'La anotación @FormKitTarget solo puede aplicarse a clases.',
        element: element,
      );
    }

    final ClassElement outputClass = element;
    final String? outputClassName = outputClass.name;
    final String generatedConfigName = '\$${outputClassName}FormConfig';
    final String generatedMapperName = '_${outputClassName}Mapper';
    final String generatedAccessName = '${outputClassName}FormKit';

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
        "// ignore_for_file: depend_on_referenced_packages, unnecessary_import");
    buffer.writeln("import 'dart:async';");
    buffer.writeln("import 'package:flutter/widgets.dart';");
    buffer.writeln("import 'package:formkit/formkit.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/contracts/icontroller_factory.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/contracts/iformkit_access.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/field_controller.dart';");
    buffer.writeln(
        "import 'package:formkit/src/flutter/core/contracts/itext_field_controller.dart';");
    buffer.writeln(
        "import 'package:formkit/src/mapping/services/value_object_converter.dart';");
    buffer.writeln(
        "import 'package:formkit/src/mapping/services/default_value_converter.dart';");

    // Importar entidad original (calculando el path)
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
        'class $generatedConfigName implements IFormSchema<$outputClassName> {');
    buffer.writeln(' const $generatedConfigName();');
    buffer.writeln('');
    buffer.writeln(' @override');
    buffer.writeln(" String get name => '${outputClassName?.toLowerCase()}';");
    buffer.writeln('');
    buffer.writeln(' @override');
    buffer.writeln(' Map<String, IFormSchema> get fields => {');

    for (final field in fields) {
      final fieldName = field.name;
      final FieldInfo info = getVoInfo(field);

      final String converter;
      final String voType = info.voType;
      final String primitiveType = info.primitiveType;

      if (info.isValueObject) {
        converter =
            'ValueObjectConverter<$primitiveType, $voType>((p) => $voType.fromValue(p as $primitiveType))';
      } else {
        converter = 'DefaultValueConverter<$voType>()';
      }

      buffer.writeln("  '$fieldName': FieldConfig<$primitiveType, $voType>(");
      buffer.writeln("   name: '$fieldName',");
      buffer.writeln("   valueConverter: $converter,");
      buffer.writeln("   initialValue: null,");
      buffer.writeln('  ),');
    }

    buffer.writeln(' };');
    buffer.writeln('}');
    buffer.writeln('');

    // --------------------------------------------------------------
    // 2. MAPPER
    // --------------------------------------------------------------

    buffer.writeln(
        '/// Mapper generado para $outputClassName (Uso interno de FormKit)');
    buffer.writeln('class $generatedMapperName implements $mapperContract {');
    buffer.writeln(' const $generatedMapperName();');
    buffer.writeln('');

    buffer.writeln(' @override');
    buffer.writeln(' $outputClassName map(Map<String, dynamic> rawValue) {');
    buffer.writeln('  return $outputClassName(');

    for (final field in fields) {
      final name = field.name;
      final voType = field.type.getDisplayString(
          withNullability: true); // Uso correcto del tipo del campo

      final raw = "rawValue['$name']";

      buffer.writeln('   $name: $raw as $voType,');
    }

    buffer.writeln('  );');
    buffer.writeln(' }');
    buffer.writeln('}');
    buffer.writeln('');

    // --------------------------------------------------------------
    // 3. ACCESS
    // --------------------------------------------------------------

    buffer.writeln(
        '/// Acceso generado para $outputClassName (Clase que el desarrollador usa)');
    buffer.writeln('class $generatedAccessName implements $accessContract {');
    buffer.writeln(' final IControllerFactory _controllerFactory;');
    buffer.writeln(' $generatedAccessName(this._controllerFactory);');
    buffer.writeln('');

    buffer.writeln(' @override');
    buffer.writeln(
        ' GlobalKey<FormState> get formKey => _controllerFactory.formKey;');
    buffer.writeln('');

    // Generar controladores fuertemente tipados
    for (final field in fields) {
      final name = field.name;
      final info = getVoInfo(field);

      String controllerType;
      // Verificación más estricta de tipos primitivos comunes para ITextFieldController
      if (info.primitiveType == 'String' ||
          info.primitiveType == 'String?' ||
          info.primitiveType == 'int' ||
          info.primitiveType == 'int?' ||
          info.primitiveType == 'double' ||
          info.primitiveType == 'double?') {
        controllerType =
            'ITextFieldController<${info.primitiveType}, ${info.voType}>';
      } else {
        controllerType =
            'IFieldController<${info.primitiveType}, ${info.voType}>';
      }

      buffer.writeln(' $controllerType get ${name}Controller {');
      buffer.writeln(
          "  final controller = _controllerFactory.getController('$name');");
      buffer.writeln('  if (controller == null) {');
      buffer.writeln(
          "   throw StateError('Controller for field \'$name\' not found. Ensure the schema is registered.');");
      buffer.writeln('  }');
      buffer.writeln('  return controller as $controllerType;');
      buffer.writeln(' }');
      buffer.writeln('');
    }

    // Método simplificado para el BLoC
    buffer.writeln(' @override');
    buffer.writeln(' Future<$outputClassName?> validatedFlush() async {');
    buffer.writeln(
        "  return _controllerFactory.validatedFlush<$outputClassName>();");
    buffer.writeln(' }');
    buffer.writeln('');

    buffer.writeln(' @override');
    buffer.writeln(
        ' Map<String, IFieldController> get allControllers => _controllerFactory.allControllers;');
    buffer.writeln('');

    buffer.writeln(' @override');
    buffer.writeln(
        ' IFieldController<P, V>? getController<P, V>(String fieldName) {');
    buffer.writeln('  final c = _controllerFactory.getController(fieldName);');
    buffer.writeln('  return c is IFieldController<P, V> ? c : null;');
    buffer.writeln(' }');

    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }
}
