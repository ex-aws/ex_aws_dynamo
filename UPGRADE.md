# Upgrading

## 3.X.X to 4.X.X

### Empty string/binary values allowed

In May, 2020, DynamoDB was updated to allow storage of empty strings and binaries in non-key fields - [documentation](https://aws.amazon.com/about-aws/whats-new/2020/05/amazon-dynamodb-now-supports-empty-values-for-non-key-string-and-binary-attributes-in-dynamodb-tables/). In earlier versions of this app, fields with empty string attributes were stripped off prior to writing to the DB by `ExAws.Dynamo.Encodable.do_encode/1`; however, in light of these developments, the default behavior of this app will now be to write empty string values.

Please check your application thoroughly and make sure you are prepared for dealing with the possibility of having empty strings in fields that may previously have been expected to return `nil` (since, in the past, they wouldn't have been written at all). To be clear, existing data is not going to be changed - but if, prior to upgrading to version 4, you wrote a record with the values `%{id: "1", optional_string: ""}`, that record will still be returned as `%{id: 1, optional_string: nil}`; if you write a record after upgrading, say `%{id: "2", optional_string: ""}`, that record will be returned exactly as written, `%{id: "2", optional_string: ""}`.

## 2.X.X to 3.X.X

### MapSet

Prior to version **2.2.0**, **ex_aws_dynamo** was encoding **MapSet** data into one of the three Dynamo set types (number, string, and binary), but was decoding those types into Elixir **List** data. In version **2.2.0**, a PR added a boolean configuration option, `:decode_sets`, that would allow the user to specify that these types should be decoded into **MapSet** as well.

In this major release, Dynamo set types decode to Elixir **MapSet** by default, so the `:decode_sets` configuration option can be removed if it was included. If it this option was not included or was explicitly set to `false`, you'll need to be prepared to handle any decoded Dynamo sets as **MapSet** instead of **List**.

### Jason

Several months ago, `ex_aws` switched its default JSON codec from **Poison** to **Jason** (see https://github.com/ex-aws/ex_aws/pull/658). In this major release, the encoder used for `dev` and `test` environments has been changed to **Jason**, and the README file has been updated to show **Jason** in use instead of **Poison**, and refers the user to the `ex_aws` docs for information about how to provide a custom JSON codec.
