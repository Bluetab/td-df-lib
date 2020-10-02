# Changelog

## [4.5.0] 2020-10-02

### Changed

- [TD-2942] Format integer and float types when string

## [4.0.0] 2020-07-01

### Changed

- Update `td_cache` to 4.0.0

## [3.25.1] 2020-06-18

### Added

- [TD-2679] Format field for user type fields

## [3.25.0] 2020-06-16

### Added

- [TD-2637] Improve support for audit of dynamic content changes
  - `TdDfLib.MapDiff` provides support for calculating diffs on maps
  - `TdDfLib.Masks` provides support for masking certain dynamic content values

## [3.24.0] 2020-06-15

- [TD-2705] Validate fixed_tuple values

## [3.23.3] 2020-05-29

### Added

- [TD-2636] `TdDfLib.Content` provides support for merging dynamic content maps

## [3.23.2] 2020-05-29

### Added

- [TD-2637] Improve support for audit of dynamic content changes
  - `TdDfLib.Diff` provides support for calculating key-wise diffs on maps
- [TD-2636] Improve support for dynamic content validation
  - `TdDfLib.Validation.validator/2` can be used to create a validator function
    that can be used by `Ecto.Changeset.validate_change/3`
- Improve support for template-related tests. `TdDfLib.TemplateFactory` can be
  used by `ExMachina` factories in other services to generate templates in tests

## [3.23.1] 2020-05-21

### Added

- [TD-2497] Numeric fields mapping

## [3.23.0] 2020-05-26

### Changed

- [TD-2629] Omit `image` fields on search values

## [3.16.0]

### Fixed

- [TD-2341] Content validation for dependent field assumes `to_be` value to be a
  list

## [3.15.0] 2020-02-12

### Added

- [TD-2335] Support for completeness calculation

## [3.14.0] 2020-01-20

### Changed

- [TD-2269] Update format to handle new content format of groups

## [3.7.0] 2019-09-16

### Added

- [TD-1625] Add table type

## [3.5.0] 2019-08-28

### Fixed

- [TD-1428] Validation for fixed values, formatting of dynamic form fields

## [3.3.2] 2019-08-02

### Fixed

- [TD-1560] Default return value in `apply_template`

## [3.3.1] 2019-08-02

### Changed

- [TD-1560] Entry point to retrieve search values

## [3.3.0] 2019-08-01

### Changed

- [TD-1560] Add validation to new `enriched_text` type

## [3.0.1] 2019-06-27

### Changed

- Use `TdCache.TemplateCache` instead of `TdPerms.DynamicFormCache` in tests

## [2.21.4] 2019-06-06

### Changed

- Bump td_perms version to 2.21.4

## [2.21.1] 2019-05-30

### Changed

- Bump td_perms version to 2.21.1

## [2.21.0] 2019-05-29

### Changed

- Bump td_perms version to 2.21.0

## [2.19.3] 2019-05-15

### Fixed

- [TD-1759] Clean library warning and fix tests

### Changed

- Decouple `TdDfLib.Validation` from cache
- Dependencies: phoenix_ecto 4.0, credo 1.0, td_perms 2.19.1
- Use `:string` as default field type

## [2.19.0] 2019-05-08

### Changed

- Bump td_perms version to 2.19.0

## [2.16.1] 2019-04-11

### Changed

- Bump td_perms version to 2.16.1

## [2.16.0] 2019-03-28

### Changed

- Bump td_perms version to 2.16.0

## [2.15.0] 2019-03-10

### Changed

- Bump td_perms version to 2.15.0

## [2.14.2] 2019-02-27

### Added

- [TD-1085] Support for applying template defaults to content

## [2.14.0] 2019-02-21

### Changed

- [TD-1422] Bump td_perms version to 2.14.0

## [2.12.1] 2019-01-28

### Changed

- [TD-1390] Bump td_perms version to 2.12.0

## [2.12.0] 2019-01-25

### Changed

- Changed validations to new content format

## [2.11.0] 2019-01-17

### Changed

- Update td-perms version to 2.11.2

## [2.10.0] 2018-12-19

### Changed

- Update to td-perms 2.10.0

## [2.8.0] 2018-11-15

### Changed

- Update to td-perms 2.8.1

## [0.1.2] 2018-11-12

### Changed

- Ignore not used dependant fields on validations

## [0.1.1] 2018-11-07

### Added

- Add `map_list` field type to validations
- Add field type validation
- Use `MockDfCache` for testing
