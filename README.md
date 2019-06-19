# ExAws.Dynamo

Service module for https://github.com/ex-aws/ex_aws

##**IMPORTANT - this is a fork!**

This package is a fork of [ex_aws_dynamo](https://hex.pm/packages/ex_aws_dynamo). It supports DynamoDB's new "billing mode" feature, which is critical for our [ecto_adapters_dynamodb](https://hex.pm/packages/ecto_adapters_dynamodb) project.

Hex requires that, for a package to be published, all of its dependencies must also be Hex packages, rather than sourced from Github/Gitlab, etc.; we (circles-learning-labs) are publishing this fork to Hex for use in our Ecto adapter until these changes have been merged into the original repository and published to Hex.

While circles-learning-labs is taking on the responsibility of publishing this package to Hex, the work itself was done by @taun - view their original fork at https://github.com/taun/ex_aws_dynamo. Thanks, @taun!

**If you need to use ex_aws_dynamo in your project, we highly recommend that you use the original Hex package, as this package may be unexpectedly deleted in the future.**

## Installation

The package can be installed by adding `ex_aws_dynamo` to your list of dependencies in `mix.exs`
along with `:ex_aws` and your preferred JSON codec / http client

```elixir
def deps do
  [
    {:ex_aws, "~> 2.0"},
    {:ex_aws_dynamo, "~> 2.0"},
    {:poison, "~> 3.0"},
    {:hackney, "~> 1.9"},
  ]
end
```

Documentation can be found at [https://hexdocs.pm/ex_aws_dynamo](https://hexdocs.pm/ex_aws_dynamo).

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
