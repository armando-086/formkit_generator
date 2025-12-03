class FieldInfo {
  final bool isValueObject;
  final String primitiveType;
  final String voType;

  FieldInfo.primitive(String type)
    : isValueObject = false,
      primitiveType = type,
      voType = type;

  FieldInfo.vo(this.primitiveType, this.voType) : isValueObject = true;
}