defmodule ElixirAmqp74Example.Client do
  use ExActor.GenServer

  @type conn :: %AMQP.Connection{pid: pid}
  @type chan :: %AMQP.Channel{conn: conn, pid: pid}

  defp rabbitmq_params do
    [
      host: "localhost",
      port: 5672,
      username: "guest",
      password: "guest",
      vhost: "/",
    ]
  end

  defstart start_link do
    chan = connect()

    # Register the pid as a named process so that it can be accessed by other
    # parts of the code by name without having to pass the pid around.
    chan.pid |> Process.register(__MODULE__.PrivateChannel)

    initial_state nil
  end

  @spec connect(keyword | nil) :: chan
  def connect(conn_params \\ rabbitmq_params()) do
    # Try to open an AMQP connection with the given connection params.
    case AMQP.Connection.open(conn_params) do
      {:ok, conn} ->
        Process.link(conn.pid) # send DOWN info when connection goes down
        {:ok, chan} = AMQP.Channel.open(conn)
        chan

      {:error, _error} ->
        :timer.sleep(5_000) # wait 5 seconds before trying again
        connect()
    end
  end

  @spec publish!(binary) :: term
  def publish!(payload) do
    # Workaround:
    # The pid has to be dereferenced from the named process because the
    # typespec `pid` only allows for literal pids, not named processes.
    # `%AMQP.Channel{pid: __MODULE__.PrivateChannel}` works, but fails
    # the dialyzer.
    pid = Process.whereis(__MODULE__.PrivateChannel)

    %AMQP.Channel{pid: pid} |> publish(payload)
  end

  defp publish(chan, payload) do
    exchange_name = "test_exchange"
    routing_key = ""

    AMQP.Basic.publish(chan, exchange_name, routing_key, payload)
  end
end
