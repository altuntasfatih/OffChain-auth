defmodule AuthFlask.Wallet.EcdSignatureTest do
  use ExUnit.Case, async: true
  require Logger

  describe "sign_message" do
    @message "This is the message that the wallet will sign."
    test "it should sign the message" do
      private_key = :crypto.strong_rand_bytes(32)
      {:ok, public_key} = ExSecp256k1.create_public_key(private_key)

      hash = ExKeccak.hash_256(@message)

      {:ok, {r_binary, s_binary, recovery_id_int}} = ExSecp256k1.sign(hash, private_key)

      signature =
        r_binary <> s_binary <> :binary.encode_unsigned(recovery_id_int)

      assert 65 == byte_size(signature)

      Logger.info("signature: #{Base.encode16(signature, case: :lower)}")
      Logger.info("public_key: #{Base.encode16(public_key, case: :lower)}")
    end

    test "it should recover public adress from signature" do
      signature =
        "26e32cfe8573b980f96718b13a155f486d0a69860f5a998398ffbbfbf5c769376fb8583fb25843151d7af72a88b1162b88e72022b15484e6637f6f105479998901"

      expected_public_key =
        "04672012f2f6e030098e5606aae3fdac788c934791e5405faf934a842b6fac66bb5d970935f1b145f30f69ab0122ae5826e7c02cfe08f3da56c4f01d3a367cd665"

      # split signature into three parts
      signature = signature |> Base.decode16!(case: :lower)
      r = binary_part(signature, 0, 32)
      s = binary_part(signature, 32, 32)
      v = binary_part(signature, 64, 1) |> :binary.decode_unsigned()

      hash = ExKeccak.hash_256(@message)

      {:ok, public_key} = ExSecp256k1.recover(hash, r, s, v)
      recovered_public_key = Base.encode16(public_key, case: :lower)

      assert(expected_public_key == recovered_public_key)

      Logger.info("recovered_public_key: #{recovered_public_key}")
    end
  end
end
