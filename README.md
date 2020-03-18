ExAws.Dynamo
============
[![Hex.pm](https://img.shields.io/hexpm/v/ex_aws_dynamo.svg)](https://hex.pm/packages/ex_aws_dynamo)
[![Build Docs](https://img.shields.io/badge/hexdocs-release-blue.svg)](https://hexdocs.pm/ex_aws_dynamo/ExAws.Dynamo.html)

Service module for https://github.com/ex-aws/ex_aws

## Installation

The package can be installed by adding `ex_aws_dynamo` to your list of dependencies in `mix.exs`
along with your preferred JSON codec and HTTP client:

```elixir
def deps do
  [
    {:ex_aws_dynamo, "~> 3.0"},
    {:jason, "~> 1.0"},
    {:hackney, "~> 1.9"}
  ]
end
```

`ex_aws` currently uses [Jason](https://github.com/michalmuskala/jason) as its default JSON codec - see [ex_aws](https://github.com/ex-aws/ex_aws) for more information about setting a custom `:json_codec`.

Documentation can be found at [https://hexdocs.pm/ex_aws_dynamo](https://hexdocs.pm/ex_aws_dynamo).

## Requirements

### DynamoDB Local

If you are running this module against a local development instance of DynamoDB, you'll want to make sure that you have installed at least version `1.11.477` (released 2019-02-06). You can find links to download the latest version [here](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.DownloadingAndRunning.html).

### Integration tests (optional)

The tests in `test/lib/dynamo/integration_test.exs` will attempt to run against a local instance of DynamoDB - in order to run these tests, you will need both a running local instance of DynamoDB as well as a `config/ddb_local_test.exs` file (.gitignored) formatted like so:

`config/ddb_local_test.exs`

```elixir
use Mix.Config

config :ex_aws,
  debug_requests: false, # set to true to monitor the DDB requests
  access_key_id: "abcd",
  secret_access_key: "1234",
  region: "us-east-1"

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: SET_YOUR_PORT,
  region: "us-east-1"
```

Before setting the `:port` and running tests, be aware that `test/lib/dynamo/integration_test.exs` will create and delete tables with the names `"TestUsers"`, `"Test.User"`, `"TestSeveralUsers"`, `"TestFoo"`, `"test_books"`, `"TestUsersWithRange"`, `"TestTransactions"`, `"TestTransactions2"` - test operations may affect your current tables if they share any of those names.

If DynamoDB is not running locally or the config file has not been provided, the integration tests will be skipped.

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
