import Config

config :ex_aws,
  debug_requests: true,
  access_key_id: "abcd",
  secret_access_key: "1234",
  region: "us-east-1"

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: 8000,
  region: "us-east-1"
