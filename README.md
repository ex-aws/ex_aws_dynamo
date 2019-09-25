# ExAws.Dynamo

Service module for https://github.com/ex-aws/ex_aws

## Installation

The package can be installed by adding `ex_aws_dynamo` to your list of dependencies in `mix.exs`
along with `:ex_aws` and your preferred JSON codec / http client

```elixir
def deps do
  [
    {:ex_aws, "~> 2.0"},
    {:ex_aws_dynamo, "~> 2.2"},
    {:poison, "~> 3.0"},
    {:hackney, "~> 1.9"},
  ]
end
```

Documentation can be found at [https://hexdocs.pm/ex_aws_dynamo](https://hexdocs.pm/ex_aws_dynamo).

## Configuration

### `decode_sets`

The default behavior of this application is to encode Elixir `MapSet` data to one of DynamoDB's three set types - number set, string set, or binary set; however, those DynamoDB datatypes will be decoded to Elixir `List`. If you wish to decode DynamoDB set types to Elixir `MapSet`, you can set the configuration for this application to include `decode_sets: true`.

For example:

```
config :ex_aws, :dynamodb,
  decode_sets: true
```

## Local testing

This application supports three test commands:

* `mix test` - run the normal test suite
* `mix test.options` - run the test suite with options enabled (see `config/test_options.exs`)
* `mix test.all` - run `mix test` and `mix test.options` sequentially

### Integration tests (optional)

The tests in `test/lib/dynamo/integration_test.exs` will attempt to run against a running local instance of DynamoDB - in order to run these tests, you will need both a running local instance of DynamoDB as well as a `config/test.exs` file (currently gitignored) formatted like so:

`config/test.exs`
```elixir
use Mix.Config

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: CHOOSE_YOUR_TEST_PORT,
  region: "us-east-1"

config :ex_aws,
  debug_requests: true,
  access_key_id: "abcd",
  secret_access_key: "1234",
  region: "us-east-1"
```

Before setting the `port`, be aware that `integration_test.exs` will create and delete tables with the names `"TestUsers", Test.User, "TestSeveralUsers", TestFoo, "test_books", "TestUsersWithRange", "TestTransactions", "TestTransactions2"` - be careful when setting the port, as these operations may interfere with your current tables if they share any of those names.

If you do not have a running local instance of DynamoDB and/or you don't provide a `config/test.exs` file, the integration tests will hang for a few seconds before returning `invalid` - this will not interfere with the successful execution of other tests.

## License

The MIT License (MIT)

Copyright (c) 2014 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
