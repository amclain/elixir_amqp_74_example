defmodule ElixirAmqp74ExampleTest do
  use ESpec, async: false

  alias ElixirAmqp74Example.Client

  let :rabbitmq_params, do: [
      host: "localhost",
      port: 5672,
      username: "guest",
      password: "guest",
      vhost: "/",
    ]

  let :exchange_name, do: "test_exchange"
  let :queue_name, do: "test_queue"

  defp setup_subscriber do
    {:ok, subscriber_connection} = rabbitmq_params() |> AMQP.Connection.open
    {:ok, subscriber_channel} = subscriber_connection |> AMQP.Channel.open

    :ok =
      subscriber_channel
      |> AMQP.Exchange.declare(exchange_name(), :direct, durable: true)

    {:ok, _} =
      subscriber_channel
      |> AMQP.Queue.declare(queue_name(), durable: true, auto_delete: false)

    :ok =
      subscriber_channel
      |> AMQP.Queue.bind(queue_name(), exchange_name())

    {:ok, _} =
      subscriber_channel
      |> AMQP.Basic.consume(queue_name(), self(), exclusive: false)

    subscriber_channel
  end

  it "sends and receives a message through AMQP" do
    payload = "hello world"

    setup_subscriber()

    {:ok, _client} = Client.start_link

    # `Client.publish!` can be called from anywhere in the code so a reference
    # to the channel doesn't need to be passed around.
    Client.publish!(payload)
    assert_receive({:basic_consume_ok, _})
    assert_receive({:basic_deliver, ^payload, _})
  end
end
