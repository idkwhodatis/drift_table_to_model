# drift_table_to_model
Dart builder to generate model classes from [drift](https://github.com/simolus3/drift) table classes

## All pull requests are welcomed to add more support or bug fix

## Quickstart
Open a terminal and execute `dart pub add drift_table_to_model`  
Put a `part models.g.dart` line in a `.dart` file  
(My recommendation is to create a `models.dart` file for easier importing)  
Open a terminal and execute `dart run build_runner build`  
A `models.g.dart` file containing generated model classes would be generated in the same directory as the file you put the `part` line  

## Name Conversion
For classes named as `nameT` or `nameTable`, generated classes would be `name`  
For classes named as `name`, generated classes would be `nameModel`

## Builder Options
- use_final  
wether to use `final` on fields
- use_const  
wether to use `const` on constructors

Create a `build.yaml` file in the root directory of your project if you dont have one  
Configure the `build.yaml` file like this:
```
targets:
  $default:
    builders:
      drift_table_to_model|drift_model_builder:
        options:
          use_final: true
          use_const: true
```
And modify `use_final` and `use_const`

## API Coverage
| Supported | Dart type   | Column         | Corresponding SQLite type                                    |
|-----------|-------------|----------------|--------------------------------------------------------------|
|    ✔️    | `int`       | `integer()`    | `INTEGER`                                                    |
|    ✔️    | `BigInt`    | `int64()`      | `INTEGER` (useful for large values on the web)               |
|    ✔️    | `double`    | `real()`       | `REAL`                                                       |
|    ✔️    | `boolean`   | `boolean()`    | `INTEGER`, with a `CHECK` to only allow 0 or 1               |
|    ✔️    | `String`    | `text()`       | `TEXT`                                                       |
|    ✔️    | `DateTime`  | `dateTime()`   | `INTEGER` (default) or `TEXT`, depending on [options](https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#datetime-options)          |
|    ✔️    | `Uint8List` | `blob()`       | `BLOB`                                                       |
|    ❌    | `Enum`      | `intEnum()`    | `INTEGER` (more information available [here](https://drift.simonbinder.eu/docs/advanced-features/type_converters/#implicit-enum-converters))             |
|    ❌    | `Enum`      | `textEnum()`   | `TEXT` (more information available [here](https://drift.simonbinder.eu/docs/advanced-features/type_converters/#implicit-enum-converters))                |

## Example
for a drift Table class:
```
import 'package:drift/drift.dart';

enum Status{
   none,
   running,
   stopped,
   paused
}

class TestT extends Table{
    IntColumn get id=>integer().autoIncrement()();
    TextColumn get name=>text()();
    RealColumn get reall=>real()();
    Int64Column get big=>int64()();
    BoolColumn get b=>boolean()();
    DateTimeColumn get dt=>dateTime()();
    BlobColumn get bl=>blob()();
    IntColumn get statusI=>intEnum<Status>()();
    TextColumn get statusT=>textEnum<Status>()();
}
```
generated class would be:  
```
class Test{
    final int id;
    final String name;
    final double reall;
    final BigInt big;
    final bool b;
    final DateTime dt;
    final Uint8List bl;
    final int statusI;
    final String statusT;

    const Test({
        required this.id,
        required this.name,
        required this.reall,
        required this.big,
        required this.b,
        required this.dt,
        required this.bl,
        required this.statusI,
        required this.statusT,
    });
}
```