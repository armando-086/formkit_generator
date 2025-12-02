import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:formkit_generator/src/utils/field_info.dart';
import 'package:formkit_generator/src/utils/value_object_checker.dart';
import 'package:collection/collection.dart';

FieldInfo getVoInfo(FieldElement field) {
  final FieldElement f = field;

  final String voType = f.type.getDisplayString();

  // 1. Verificar si el campo implementa o extiende ValueObject
  if (valueObjectChecker.isAssignableFromType(f.type) &&
      f.type is InterfaceType) {
    final InterfaceType fieldType = f.type as InterfaceType;

    final DartType? voSuperType = fieldType.allSupertypes.firstWhereOrNull(
      (t) => valueObjectChecker.isExactlyType(t),
    );

    if (voSuperType != null && voSuperType is InterfaceType) {
      if (voSuperType.typeArguments.isNotEmpty) {
        final primitiveType = voSuperType.typeArguments.first
            .getDisplayString();
        return FieldInfo.vo(primitiveType, voType);
      }
    }
  }

  return FieldInfo.primitive(voType);
}
