# drift_table_to_model
Dart builder to generate model classes from [drift](https://github.com/simolus3/drift) table classes

## Quickstart
Open a terminal and execute `dart pub add drift_table_to_model`  
Put a `part models.g.dart` line in a `.dart` file  
(My recommendation is to create a `models.dart` file for easier importing)  
Open a terminal and execute `dart run build_runner build`  
A `models.g.dart` file containing generated model classes would be generated in the same directory as the file you put the `part` line  

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

## All pull requests are welcomed to add more support or bug fix
