library;

import 'dart:async';
import 'dart:io';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';

class DriftModelGenerator extends Generator{
    bool hasBlob=false;
    final bool useFinal;
    final bool useConst;

    DriftModelGenerator(this.useFinal,this.useConst);

    @override
    FutureOr<String?> generate(LibraryReader library,BuildStep buildStep){
        final modelClasses=<String>[];
        for(final element in library.classes){
            if(element.supertype!=null&&element.supertype!.element.name=='Table'){
                final className=element.name;

                final String modelClassName;
                if(className.endsWith('Table')){
                    modelClassName=replaceLast(className,'Table','');
                }else if(className.endsWith('T')){
                    modelClassName=replaceLast(className, 'T', '');
                }else{
                    modelClassName=className+'Model';
                }

                final fields=<String,String>{};
                for(var field in element.fields){
                    final type=_getFieldType(field);
                    if(type!=null){
                        if(type=='Uint8List'){
                            hasBlob=true;
                        }
                        fields[field.name]=type;
                    }
                }

                final String modelClass=_generateModelClass(modelClassName,fields);
                if(modelClass.isNotEmpty){
                    modelClasses.add(modelClass);
                }
            }
        }
        return modelClasses.join('\n\n');
    }

    String? _getFieldType(FieldElement field){
        final match=RegExp(r'Column<(.+)>').firstMatch(field.type.getDisplayString());
        if(match!=null){
            return match.group(1);
        }
        return null;
    }

    String _generateModelClass(String className,Map<String,String> fields){
        final buffer=StringBuffer();
        String finalField=useFinal?'final ':'';
        String constField=useConst?'const ':'';

        buffer.writeln('class $className{');
        fields.forEach((name,type){
            buffer.writeln('    $finalField$type $name;');
        });
        buffer.writeln();

        buffer.writeln('    $constField$className({');
        fields.forEach((name,type){
            buffer.writeln('        required this.$name,');
        });
        buffer.writeln('    });');
        buffer.writeln('}');

        return buffer.toString();
    }

    static String replaceLast(String string,String from,String to){
        int lastIndex=string.lastIndexOf(from);
        if(lastIndex==-1){
            return string;
        }
        return string.substring(0,lastIndex)+to+string.substring(lastIndex+from.length);
    }
}

class DriftModelBuilder extends Builder{
    String outputPath='';
    final bool useFinal;
    final bool useConst;

    DriftModelBuilder(this.useFinal,this.useConst);

    @override
    Future<void> build(BuildStep buildStep) async{
        final code=<String>[];
        bool hasBlob=false;
        String partFile='';

        await for(final input in buildStep.findAssets(Glob('lib/**/*.dart'))){
            if(p.basename(input.path).contains('.g.dart')){
                continue;
            }
            if(RegExp(r'''part\s+['"]models.g.dart['"]\s*;''').hasMatch(await buildStep.readAsString(input))){
                outputPath=p.dirname(input.path);
                partFile=p.basename(input.path);
            }

            final LibraryElement library;
            try{
                library=await buildStep.resolver.libraryFor(input);
            }catch(e){
                continue;
            }
            final generator=DriftModelGenerator(useFinal,useConst);
            
            final generatedCode=await generator.generate(LibraryReader(library),buildStep);
            if(generatedCode!=null){
                code.add(generatedCode);
            }
            if(generator.hasBlob){
                hasBlob=true;
            }
        }

        if(outputPath.isNotEmpty){
            if(hasBlob){ 
                final file=File(p.join(outputPath,partFile));
                final lines=await file.readAsLines();

                if(!lines.any((line)=>line.contains("import 'dart:typed_data';"))){
                    int insertIndex=lines.indexWhere((line)=>!line.startsWith('import'));

                    if(insertIndex==-1){
                        insertIndex=0;
                    }
                    lines.insert(0,"import 'dart:typed_data';\n");

                    await file.writeAsString(lines.join('\n'));
                }
            }
            code.insert(0,"// Autogenerated code by drift_table_to_model\npart of '$partFile';");

            await buildStep.writeAsString(AssetId(buildStep.inputId.package,p.join('lib','models.g.dart')),code.join('\n\n'));

            final generatedFile=File(p.join('lib','models.g.dart'));
            if(await generatedFile.exists()){
                await generatedFile.copy(p.join(outputPath,'models.g.dart'));
            }
        }
    }

    @override
    Map<String,List<String>> get buildExtensions{
        return const {r'$lib$':['models.g.dart']};
    }
}

class DriftModelPostProcessBuilder extends PostProcessBuilder{
    @override
    FutureOr<void> build(PostProcessBuildStep buildStep) async{
        final generatedFile=File(buildStep.inputId.path);
        if(await generatedFile.exists()){
            await generatedFile.delete();
            log.info('Deleted file: ${buildStep.inputId.path}');
        }
    }

    @override
    Iterable<String> get inputExtensions=>['models.g.dart'];
    
}

void logToFile(String message){
    final file=File('debug_log.txt');
    file.writeAsStringSync(message+'\n', mode: FileMode.append);
}

Builder driftModelBuilderFactory(BuilderOptions options){
    return DriftModelBuilder(options.config['use_final'] as bool? ?? true,options.config['use_const'] as bool? ?? true);
}

PostProcessBuilder driftModelPostProcessBuilderFactory(BuilderOptions options)=>DriftModelPostProcessBuilder();