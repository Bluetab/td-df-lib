# Changelog

## [Unreleased]

## Changed

- [TD-7676] Concept completeness must ignore dependent fields when their condition isn’t met.

## [7.14.0] 2025-12-04

### Fix

- [TD-7619] Fix date and datetime format and validation

## [7.12.1] 2025-12-03

## Changed

- [TD-7746] Add optional context parameter to `append_parsed_fields/4`
  and expose `context_for_fields/2` to enable context reuse and reduce redundant cache lookups

## [7.12.0] 2025-10-28

### Added

- [TD-7340]:
  - Template validations for `dynamic_table` fields
  - Apply template to entity content for `dynamic_table` fields
  - Format `dynamic_table` fields content for file upload and download

## [7.11.1] 2025-09-30

### Added

- [TD-7401] Update td-cache lib to add maxlen limit in streams

## [7.11.0] 2025-09-24

### Added

- [TD-7301] Update td-cache to add Link Approvals

## [7.7.0] 2025-06-20

### Added

- [TD-7300] Update td-cache lib to add Link origin

## [7.6.0] 2025-06-06

### Changed

- [TD-6468] Expand parsed fields in all active languages if translations

## [7.5.0] 2025-05-22

### Changed

- [TD-6219] Update td-cache version

## [7.4.0] 2025-04-09

### Changed

- License

## [7.1.2] 2025-02-04

### Added

- [TD-5119] add validation for template dependant fields

## [7.1.1] 2025-02-03

### Added

- [TD-6022] add validation for template hierarchy fields

## [7.1.0] 2025-01-29

### Changed

- [TD-6921] Change URL type field parser

## [7.0.3] 2025-01-13

### Changed

- [TD-3612] Update td-cache

## [7.0.2] 2025-01-10

### Added

- [TD-5713] Gets flatten content schema for scope

## [7.0.1] 2025-01-07

### Changed

- [TD-6911] Bump to Elixir 1.18 and updated dependencies

## [7.0.0] 2025-01-02

### Changed

- [TD-7011] Format.search_values/2 doesn't apply default values when specified

## [6.15.0] 2024-11-27

### Changed

- [TD-6908] Update td-df-lib

## [6.14.1] 2024-11-07

### Changed

- [TD-6880] Add table type fields with no rows are returned as empty string.

## [6.14.0] 2024-10-25

### Added

- [TD-6880] Use a CSV-like format to define table fields in Excel, including parsing for both upload and download processes.

## [6.13.4] 2024-10-14

### Added

- [TD-6617] Hint for required validations over fields with multiple cardinality

## [6.13.3] 2024-10-10

### Fixed

- [TD-6773] Returns error for numbers with float format

## [6.13.2] 2024-10-10

### Added

- [TD-6773] Require validation for table field columns in dynamic forms content.

### Changed

- [TD-6773] Validate number fields on format parsing.

## [6.13.1] 2024-10-09

### Changed

- [TD-6469] Updates `td-cache` version for compatibility.

## [6.13.0] 2024-10-07

### Added

- [TD-6817]:
  - Inclusion validation for `user` and `user_group` template fields.
  - Process `user` and `user_group` template field binary values with multiple cardinality and `|` separator.

## [6.9.6] 2024-07-29

### Fixed

- [TD-6734] Adjust Template.visible_fields/2 for legacy content

## [6.9.5] 2024-07-26

### Fixed

- [TD-6733] Adjust Format.set_cached_value/2 for legacy content

## [6.9.4] 2024-07-24

### Fixed

- [TD-6723-2] hierarchy cached values

## [6.9.3] 2024-07-24

### Added

- [TD-6689] Update td-cache lib

## [6.9.2] 2024-07-24

### Fixed

- [TD-6723] Adjust Format.set_cached_value/2 for new content structure

## [6.9.1] 2024-07-19

### Fixed

- [TD-6713] Adjust Format.set_search_value/2 for new content structure

## [6.9.0] 2024-07-10

### Changed

- [TD-6602] Update td-cache

## [6.8.2] 2024-06-25

### Added

- [TD-6499] Add support for legacy API connections

## [6.8.1] 2024-06-17

### Fixed

- [TD-6499] Fix hierarchy preview

## [6.8.0] 2024-06-13

### Added

- [TD-6499] Manage template contents with origins

## [6.7.0] 2024-06-11

### Fixed

- [TD-6440] Fix hierarchy bug

## [6.5.1] 2024-04-30

### Added

- [TD-6492] Enriches hierarchy path

## [6.5.0] 2024-04-03

### Fixed

- [TD-6424] Traslate fields of type switch on

## [6.4.0] 2024-04-03

## [6.3.1] 2024-04-04

### Fixed

- [TD-6507] Add url case to format search value

## [6.3.0] 2024-03-13

### Added

- [TD-4110] Allow structure scoped permissions management

## [6.2.1] 2024-04-04

### Fixed

- [TD-6507] Add url case to format search value

## [6.2.0] 2024-02-24

### Added

- [TD-6258] Get default lang by cache

## [6.1.0] 2024-04-03

### Fixed

- [TD-6507] Add url case to format search value

## [6.0.0] 2024-01-16

### Added

- [TD-6195] Functions for parsing AiSugestion fields

## [5.20.0] 2023-12-13

### Added

- [TD-6215] bump version due to updated references

## [5.18.0] 2023-11-10

### Fixed

- [TD-6177] Fixes error when formatting negative values as integer or float

## [5.17.0] 2023-10-31

### Added

- [TD-6059] Support for validation functionality using td-cluster implementation

## [5.15.0] 2023-10-17

### Fixed

- [TD-6082] Format fields use template fields name instead of labels

## [5.14.0]

### Added

- [TD-5929] Translate fixed values if is possible using i18n key
  - Detailed errors by fields

## [5.12.2] 2023-08-16

### Fixed

- [TD-5913] Test depends_on validation for multiple cardinality

## [5.12.1] 2023-08-14

### Changed

- [TD-5891] Update td-cache version

## [5.12.0] 2023-08-14

### Added

- [TD-5891] Add i18n cache messages

## [5.11.0] 2023-07-14

### Changed

- [TD-5844] Change in parser for get from domain widget name or external id

## [5.8.1] 2023-06-05

### Changed

- [TD-5697] Use `HierarchyCache.get_node/1`

## [5.8.0] 2023-05-25

### Added

- [TD-3916] Hierarchy depth validation

## [5.5.0] 2023-03-29

### Added

- [TD-5650] Format and validations for hierarchies

## [5.4.1] 2023-03-27

### Added

- [TD-5685] Stringfy keys before enriching cache content

## [5.4.0] 2023-03-23

### Added

- [TD-4870] Create Parser for unifying dynamic form csv download and upload

## [5.3.2] 2023-03-13

### Changed

- [TD-3806] Refactor Hierarchy get cache data with key hierarchy_id and node_id

## [5.3.1] 2023-03-09

### Fixed

- [TD-3806] Update lib dependencies

## [5.3.0] 2023-03-09

### Added

- [TD-3806] Hierarchy formater

## [4.54.0] 2022-10-26

### Changed

- [TD-5284] Update dependencies

## [4.53.1] 2022-10-17

### Changed

- [TD-5254] Completeness calculation now considers "switch" fields when
  determining field visibility

## [4.53.0] 2022-10-03

### Changed

- [TD-4857] Completeness calculation now considers ratio of completed
  visible fields rather than completed optional fields

## [4.50.0] 2022-08-29

### Changed

- [TD-5091] `domain` fields are now stored as integers instead of embedded
  documents

## [4.48.0] 2022-07-12

### Fixed

- [TD-5011] `TemplateCache.list/0` was returning duplicate entries

## [4.46.0] 2022-06-15

### Added

- [TD-4739] Support validation of potentially unsafe content

## [4.45.0] 2022-05-31

### Changed

- [TD-3920] `TdDfLib.Format.apply_template/3` takes only template fields of the
  content

## [4.44.0] 2022-05-20

### Added

- [TD-4548] Format support for multiple selection fields separted by `|`

## [4.40.1] 2022-03-11

### Changed

- [TD-4500] Support for `domain_ids` opt in `Format.set_default_value` and
  `Validation.build_changeset/2`

## [4.40.0] 2022-03-07

### Fixed

- [TD-4491] Use `TaxonomyCache.get_by_external_id/1` to read domain from cache,
  only if `external_id` is a valid identifier

## [4.36.1] 2022-01-24

### Fixed

- [TD-4125] `TemplateFactory` now returns groups and fields with binary keys
  instead of atom keys

## [4.36.0] 2022-01-19

### Fixed

- [TD-4312] Prevent identifier change if a new version is created

## [4.35.0] 2022-01-04

### Added

- [TD-4312] Autogenerated template identifier field

## [4.31.0] 2021-10-20

### Added

- [TD-4124] Format domain dependent field

## [4.28.0] 2021-09-13

### Added

- [TD-3971] Mandatory field depending on previous field value

## [4.27.0] 2021-09-02

### Added

- [TD-3973] Default value over switch fields

## [4.25.0] 2021-07-26

### Changed

- Update `td_cache` to 4.25.4

## [4.21.0] 2021-05-28

### Changed

- [TD-3502]
  - Image type validation
  - Update cache version

## [4.15.0] 2021-03-05

### Changed

- [TD-3063] Get subscribable fields from template

## [4.12.0] 2021-01-13

### Changed

- Updated dependencies

## [4.11.0] 2020-12-16

### Changed

- Updated dependencies

## [4.10.0] 2020-11-30

### Added

- [TD-2486] Template type `domain`

## [4.9.1] 2020-11-27

### Changed

- Updated dependencies

## [4.9.0] 2020-11-17

### Added

- [TD-3089] Copy type fields

## [4.6.0] 2020-10-19

### Added

- [TD-2485] System type fields

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

## [3.16.0] 2020-02-18

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
