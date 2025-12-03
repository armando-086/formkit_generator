// ignore_for_file: depend_on_referenced_packages, deprecated_member_use
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:formkit_generator/type_checker/value_object_checker.dart';
import 'package:formkit_generator/utils/field_info.dart';

FieldInfo getVoInfo(FieldElement field) {
  final FieldElement f = field;

  final String voType = f.type.getDisplayString(withNullability: true);

  // 1. Verificar si el campo implementa o extiende ValueObject
  if (valueObjectChecker.isAssignableFromType(f.type) &&
      f.type is InterfaceType) {
    final InterfaceType fieldType = f.type as InterfaceType;

    //. Buscar el supertipo ValueObject para extraer el argumento de tipo primitivo
    final DartType? voSuperType = fieldType.allSupertypes.firstWhereOrNull(
      (t) => valueObjectChecker.isExactlyType(t),
    );

    if (voSuperType != null && voSuperType is InterfaceType) {
      if (voSuperType.typeArguments.isNotEmpty) {
        final primitiveType = voSuperType.typeArguments.first
            .getDisplayString(withNullability: true);
        return FieldInfo.vo(primitiveType, voType);
      }
    }
  }

  return FieldInfo.primitive(voType);
}