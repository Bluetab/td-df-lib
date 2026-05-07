import Config

config :git_hooks,
  auto_install: true,
  hooks: [
    pre_commit: [
      tasks: [
        {:cmd, "mix format --check-formatted"}
      ]
    ]
  ]
