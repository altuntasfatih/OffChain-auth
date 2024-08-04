defmodule OffChainAuthWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import OffChainAuthWeb.ConnCase

      alias OffChainAuthWeb.Router.Helpers, as: Routes

      @endpoint OffChainAuthWeb.Endpoint
    end
  end

  # ... rest of the file remains the same ...
end
