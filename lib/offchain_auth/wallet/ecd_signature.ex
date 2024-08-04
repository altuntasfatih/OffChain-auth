defmodule OffChainAuth.Wallet.EcdSignature do
  require Logger

  # signature scheme
  # "\x19Ethereum Signed Message:\n" + message.length + message
  @eth_eip_4361_prefix "\x19Ethereum Signed Message:\n"

  def verify?(%{
        message: message,
        signature: "0x" <> signature,
        address: address
      }) do
    signature = signature |> Base.decode16!(case: :lower)

    r = binary_part(signature, 0, 32)
    s = binary_part(signature, 32, 32)
    v = binary_part(signature, 64, 1) |> :binary.decode_unsigned()
    recovery_id = if v >= 27 and v < 27 + 4, do: v - 27, else: v

    hashed_message = ExKeccak.hash_256(@eth_eip_4361_prefix <> "#{byte_size(message)}" <> message)

    case recover_wallet_address(hashed_message, r, s, recovery_id) do
      {:ok, recovered_address} ->
        String.downcase(address) == String.downcase(recovered_address)

      err ->
        Logger.error("Public key recovery failed: #{inspect(err)}")
        false
    end
  end

  defp recover_wallet_address(hashed_message, r, s, recovery_id) do
    with {:ok, public_key} <- ExSecp256k1.recover(hashed_message, r, s, recovery_id) do
      {:ok, address(public_key)}
    end
  end

  def address(public_key) do
    address =
      public_key
      |> pub_key_64_bytes()
      |> ExKeccak.hash_256()
      |> get_last_20_bytes()
      |> Base.encode16(case: :lower)

    "0x" <> address
  end

  defp get_last_20_bytes(<<_::binary-12, address::binary-20>>), do: address

  defp pub_key_64_bytes(<<_::binary-size(1), response::binary-size(64)>>), do: response
  defp pub_key_64_bytes(key) when byte_size(key) == 64, do: key
end
