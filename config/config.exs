import Config

config :td_df_lib, :templates_module, TdCache.TemplateCache

import_config "#{config_env()}.exs"
