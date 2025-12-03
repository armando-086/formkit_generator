// ignore_for_file: depend_on_referenced_packages
import 'package:build/build.dart';
import 'package:formkit_generator/generator/formkit_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder formKitMapperBuilder(BuilderOptions options) {
  return LibraryBuilder(
    const FormKitGenerator(),
    generatedExtension: '.formkit_mapper.dart',
  );
}
