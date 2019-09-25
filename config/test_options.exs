use Mix.Config
require Logger

config :ex_aws, :dynamodb,
  decode_sets: true

import_config "test.exs"
