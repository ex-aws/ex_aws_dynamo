# Changelog

## v4.0.2 - 2021-12-24

- Add :consistent_read option in scan_opts spec
- Add `code_quality` alias
- Adds dialyxir to dev dependencies
- Various credo and dialyzer fixes
- Fixes typos in documentation and README

## v4.0.1 - 2021-04-26

- Update dependencies
- Update documentation

## v4.0.0 - 2020-07-06

- Add support for empty string/binary attributes
- Empty string is saved as a space when using `put_item`

## v3.0.3 - 2020-07-03

- Update dependencies

## v3.0.2 - 2020-05-23

- Add empty prod.exs config file

## v3.0.1 - 2020-05-04

- Upcase `return_consumed_capacity` values on batch calls
- Documentation updates and fixes

## v3.0.0 - 2020-02-22

- Set minimum version of `ex_aws` to 2.1.2
- Remove reference to `:decode_sets_config` option

## v2.3.4 - 2019-10-31

- Additional documentation changes
- Set `config/test.exs` as a 'bare-bones' config file
- Import `ddb_local_test.exs` only if it has been provided.

## v2.3.3 - 2019-10-24

- Allow `expression_attribute_names` to be specified in `batch_get_item`
- Add badges to documentation

## v2.3.2 - 2019-10-20

- Set `:debug_requests` to false in `test.exs.example`
- Run integration tests only local DDB instance found

## v2.3.1 - 2019-10-07

- Fix documentation

## v2.3.0 - 2019-09-27

- Add DynamoDb transaction API calls
- Code formatting

## v2.2.2 - 2019-09-25

- Add instructions on running integration tests against local DDB

## v2.2.1 - 2019-08-27

- Properly handle Binary fields

## v2.2.0 - 2019-08-12

- Fix type `expression_attribute_values_vals`
- Decode sets as MapSet

## v2.1.0 - 2019-07-19

- Add support for billing mode
- Add ability to specify billing mode and TTL during table create and update
- Add support for list of items while decoding
- Add `Dynamo.update_time_to_live` and `Dynamo.describe_time_to_live`

## v2.0.0 - 2017-11-10

- Major Project Split. Please see the main [ExAws](https://github.com/ex-aws/ex_aws) repository for [previous changelogs](https://github.com/ex-aws/ex_aws/blob/master/CHANGELOG.md).
