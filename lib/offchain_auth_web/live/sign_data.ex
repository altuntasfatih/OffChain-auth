defmodule OffChainAuthWeb.SignData do
  use OffChainAuthWeb, :live_view
  require Logger

  alias OffChainAuth.Wallet.EcdSignature

  @metamask_provider_id "io.metamask"
  @nonce_length 8
  @default_data %{
    operation: "offchain authentication",
    host: "",
    nonce: ""
  }

  # Types
  @type t :: %{
          address: String.t() | nil,
          connected: boolean(),
          signature: String.t() | nil,
          provider: String.t(),
          encoded_data: String.t(),
          data: any()
        }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, init(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md relative"
      id="web3-connect-container"
      phx-hook="Web3Connect"
    >
      <h2 class="text-2xl font-bold mb-6 text-gray-900">Off-Chain Authentication</h2>
      
    <!-- Status Indicator in Top Right -->
      <div class="absolute top-6 right-6 flex items-center gap-2">
        <div class={[
          "w-3 h-3 rounded-full",
          (@connected && "bg-green-500") || "bg-red-500"
        ]}>
        </div>
        <span class="text-sm text-gray-600">
          {if @connected, do: "Connected", else: "Not connected"}
        </span>
      </div>
      
    <!-- Wallet Address Section -->
      <div :if={@address != nil} class="mb-6 p-4 bg-gray-50 rounded-lg">
        <.label>Address:</.label>
        <div class="mt-1 font-mono text-sm break-all">
          {@address}
        </div>
      </div>
      
    <!-- Data Section -->
      <div :if={@connected}>
        <.label>Data to be signed:</.label>
        <div class="mb-6 p-4 bg-gray-50 rounded-lg">
          <div class="mt-1">
            <dl class="font-mono text-sm divide-y divide-gray-200">
              <%= for {key, value} <- @data do %>
                <div class="py-2 flex gap-2">
                  <dt class="text-gray-600">{key}:</dt>
                  <dd class="text-gray-900 break-all">{value}</dd>
                </div>
              <% end %>
            </dl>
          </div>
        </div>
      </div>
      
    <!-- Signature Section -->
      <div :if={@signature != nil} class="mb-6 p-4 bg-green-50 rounded-lg">
        <.label>Signature is valid:</.label>
        <div class="mt-1 font-mono text-sm break-all text-green-600">
          {@signature}
        </div>
      </div>
      
    <!-- Action Buttons Section -->
      <div class="flex items-center justify-center mt-8">
        <.button
          :if={not @connected}
          phx-click="connect"
          class="flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-colors"
        >
          <img src="/images/metamask-fox.svg" class="w-5 h-5" alt="MetaMask" /> Connect
        </.button>

        <.button
          :if={@connected && is_nil(@signature)}
          phx-click="sign"
          class="flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-colors"
        >
          <img src="/images/key.svg" class="w-5 h-5" alt="Key" /> Sign
        </.button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("sign", _, socket) do
    socket =
      socket
      |> assign(:encoded_data, Jason.encode!(socket.assigns.data, pretty: true))
      |> push_event("web3-connect:sign-data", %{
        data: socket.assigns.encoded_data,
        pretty: true
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("connect", _, socket) do
    {:noreply,
     push_event(socket, "web3-connect:select-provider", %{provider: @metamask_provider_id})}
  end

  @impl true
  def handle_event(
        "web3-connect:signed-data",
        %{"signature" => signature},
        %{assigns: assigns} = socket
      ) do
    if EcdSignature.verify?(%{
         message: assigns.encoded_data,
         signature: signature,
         address: assigns.address
       }) do
      {:noreply, assign(socket, :signature, signature)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid signature. Please try signing again.")}
    end
  end

  @impl true
  def handle_event("web3-connect:connection-error", err, socket) do
    Logger.error("connection error: #{inspect(err)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "web3-connect:connected",
        %{
          "provider" => %{
            "address" => address,
            "id" => @metamask_provider_id,
            "is_connected" => true
          }
        },
        socket
      ) do
    socket =
      socket
      |> assign(:address, address)
      |> assign(:connected, true)
      |> assign(:encoded_data, Jason.encode!(socket.assigns.data, pretty: true))

    {:noreply, socket}
  end

  @impl true
  def handle_event("web3-connect:detected-providers", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("web3-connect:injected-provider-not-detected", _, socket),
    do: {:noreply, socket}

  defp init(socket) do
    socket
    |> assign(:connected, false)
    |> assign(:address, nil)
    |> assign(:provider, nil)
    |> assign(:signature, nil)
    |> assign(:encoded_data, nil)
    |> assign(
      :data,
      Map.merge(@default_data, %{
        host: OffChainAuthWeb.Endpoint.host(),
        nonce: random_string()
      })
    )
  end

  defp random_string, do: :crypto.strong_rand_bytes(@nonce_length) |> Base.encode16()
end
