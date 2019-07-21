locals_without_parens = [
  boot_step: 1,
  boot_step: 2,
  boot_step: 3
]

[
  inputs: ["mix.exs", "{config,lib.test}/**/*{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
