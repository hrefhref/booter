# Booter

Complicated applications can be composed of multiple subsystems or groups or processes, independants or dependants of
each others. And starting theses subsystems is not easy as `:application.start/2` or a supervisor child spec.

Booter allows modules to define a list of **boot steps** using Module attributes. Each step define what to call, what
it requires and enables. A directed acyclic graph is then created from theses steps, and called in the correct order.

Inspired/adapted to Elixir by RabbitMQ's boot process implemented in [rabbit.erl][1] and [rabbit_misc.erl][2]. For an
in-depth explaination, read Alvaro Videla's [article][3] and [slides][2].

## Usage

[Read the API documentation for full usage][exdoc].

### Defining boot steps

Using `Booter` and the `boot_step/3` macro:

```elixir
defmodule MyModule do
  use Booter

  # without name (__MODULE__ is assumed)
  boot_step mfa: {mod, fun, args}, requires: :required_step, enables: :another_step

  # with name
  boot_step :awesome_name, mfa: {mod, fun, args}, requires: :required_step, enables: :another_step

  # With name and description
  boot_step :awesome_name, "Unicorn generator", mfa: {mod,fun,args}, requires: :rainbow_server, enables: :magic
end
```

### Start boot

Just call `Booter.boot!`. Can raise exceptions.

[exdoc]: http://eraserewind.github.io/booter/
[1]: https://github.com/videlalvaro/rabbit-internals/blob/master/rabbit_boot_process.md
[2]: http://fr.slideshare.net/old_sound/rabbitmq-boot-system
[2]: https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit.erl
[3]: https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit_misc.erl

