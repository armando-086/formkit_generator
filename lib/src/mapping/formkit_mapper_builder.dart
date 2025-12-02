import 'package:build/build.dart';
import 'package:formkit_generator/src/mapping/formkit_mapper_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder formkitMapperBuilder(BuilderOptions options) {
  return SharedPartBuilder(
      [FormKitMapperGenerator()], 'formkit_mapper');
}