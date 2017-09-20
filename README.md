# Elixir Amqp 74 Example

This repo is a reproduction of the error reported in [pma/amqp#74](https://github.com/pma/amqp/pull/74).

## Issue

The [`AMQP.Basic.publish` spec](https://github.com/pma/amqp/blob/0154d7ed0e3e139d63eb4adf0471756fcf2b0799/lib/amqp/basic.ex#L50)
has a flaw where it raises a typespec error when only trying to pass a channel
pid. The code executes and works as expected.

## Repo Layout

* [`lib/client.ex`](lib/client.ex) is an AMQP client that reproduces the
scenario where we want to be able to `publish!` from various parts of the code
without having to reference the channel pid when calling `publish!`. To do this
we register the pid as a named process.

* [`spec/integration_spec.exs`](spec/integration_spec.exs) is a test that
shows a message being published to RabbitMQ and received by a subscriber.
This verifies that the design is valid.

## Reproducing The Issue

* Clone this repo: `git clone git@github.com:amclain/elixir_amqp_74_example.git`
* Ensure [Docker CE](https://www.docker.com/community-edition#/download) is installed.
* Run the RabbitMQ container:

```text
docker run -d --rm --name amqp74 -p 5672:5672 -e "RABBITMQ_SERVER_START_ARGS=-rabbit loopback_users []" rabbitmq:3.6.10-alpine
```

* Install dependencies: `mix deps.get`
* Run the tests: `mix test` (Tests should pass. If not, ensure RabbitMQ container is up.)
* Run the dialyzer: `mix dialyzer`
* The dialyzer will fail with the following warnings:

```text
lib/client.ex:43: Function 'publish!'/1 has no local return
lib/client.ex:52: Function publish/2 has no local return
lib/client.ex:56: The call 'Elixir.AMQP.Basic':publish(chan@1::#{'__struct__':='
Elixir.AMQP.Channel', 'conn':='nil', 'pid':='nil' | pid() | port()},
exchange_name@1::<<_:104>>,routing_key@1::<<>>,payload@1::any()) will never
return since it differs in the 1st argument from the success typing arguments:
(#{'__struct__':='Elixir.AMQP.Channel', 'conn':=#{'__struct__':='
Elixir.AMQP.Connection', 'pid':=pid()}, 'pid':=pid()},binary(),binary(),binary())
done (warnings were emitted)
```

This reproduces the typespec issue with `AMQP.Basic.publish` being specified as:
```elixir
@spec publish(Channel.t, String.t, String.t, String.t, keyword) :: :ok | error
```

This error occurs because `Channel.t` requires both a `:pid` and `:conn`, but we
are only passing a pid.

## The Fix

* Edit `mix.exs`
  * Comment out `{:amqp, "0.3.0"},`
  * Uncomment `{:amqp, git: "https://github.com/amclain/amqp.git", ref: "33bf97f"},`
* Install dependencies: `mix deps.get`
* Run the tests: `mix test` (Tests should pass.)
* Run the dialyzer: `mix dialyzer` (Should pass.)

PR [pma/amqp#74](https://github.com/pma/amqp/pull/74) updates the
`AMQP.Basic.publish` spec to the following:

```elixir
@spec publish(%Channel{pid: pid}, String.t, String.t, String.t, keyword) :: :ok | error
```

This allows for an `%AMQP.Channel` to be created with only a pid, since the
`%AMQP.Connection` part of `Channel.t` is not required and not used by the
`AMQP.Basic.publish` function.

## Stopping The RabbitMQ Docker Container

```text
docker stop amqp74
```

The container will be removed once it's stopped.
