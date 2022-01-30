import Config
# Only attempt to load config for DDB local if
# a config has been explicitly provided. See README.
if File.exists?("config/ddb_local_test.exs") do
  import_config "ddb_local_test.exs"
end
