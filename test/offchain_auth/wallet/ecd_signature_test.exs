defmodule OffchainAuth.Wallet.EcdSignatureTest do
  use ExUnit.Case, async: true
  alias OffChainAuth.Wallet.EcdSignature

  test "valid signature verifies correctly" do
    message =
      "{\n  \"host\": \"localhost\",\n  \"operation\": \"offchain authentication\",\n  \"nonce\": \"6A04834EBC7F0D62\"\n}"

    address = "0x02FA9d333a7F8a3B5F6eF598006D7C6c8e56cf32"

    signature =
      "0xebaa0e14b2f8140e9701bd3e82bf67d5f7a813a8df3ad2c429716670374bed257dd7df9b447ba34842723b2cf50cdddf85a7a4cf738154ba96ebe7cbfa1787a61b"

    assert EcdSignature.verify?(%{message: message, signature: signature, address: address})
  end

  test "invalid signature fails verification" do
    message = "Test message"
    address = "0x02FA9d333a7F8a3B5F6eF598006D7C6c8e56cf31"
    signature =
      "0xebaa0e14b2f8140e9701bd3e82bf67d5f7a813a8df3ad2c429716670374bed257dd7df9b447ba34842723b2cf50cdddf85a7a4cf738154ba96ebe7cbfa1787a61b"

    refute EcdSignature.verify?(%{message: message, signature: signature, address: address})
  end

end
