# Boater

Boot your application, step by step. Inspired by [RabbitMQ's boot process][1], steps are defined in a module attribute
`@boot_step`, sorted by `requires`/`enables`, and executed.

If any of the steps fails, it will exits the application.

In `application.start/2` :

    def start(_type, _args) do
      { :ok, sup } = Supervisor.start_link
      Boater.boot!
      { :ok, sup }
    end

In your modules :

    defmodule My.Module do
      use Boater

      @boot_step { :awesome_step_name, [
        { :description, "Awesome step, does awesome things" },
        { :mfa, { Supervisor, :start_child, [My.Module] },
        { :requires, :another_awesome_step },
        { :enables, :overload_of_awesomeness_step },
    end

Goodies

    Boater.boot_steps #=> Sorted boot steps
    Boater.unsorted_boot_steps #=> Sorted boot steps
    Boater.boot_order #=> Ordered steps names

Copied and adapter to Elixir from [rabbit.erl][2], [rabbit_misc.erl][3].

[1]: https://github.com/videlalvaro/rabbit-internals/blob/master/rabbit_boot_process.md
[2]: https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit.erl
[3]: https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit_misc.erl

