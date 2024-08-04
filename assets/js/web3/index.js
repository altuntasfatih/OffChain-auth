import { mainnet } from '@wagmi/core/chains'
import { injected } from '@wagmi/connectors'
import {
  createStorage,
  createConfig,
  http,
  disconnect,
  reconnect,
  connect,
  signMessage,
  getConnections,
  getConnectors,
} from "@wagmi/core"

const storage = createStorage({ storage: localStorage })

class Web3ConnectionProvider {
  constructor() {
    this.config = null
  }

  init() {
    this.config = createConfig({
      chains: [mainnet],
      storage,
      connectors: [
        injected({
          dappMetadata: {
            name: "OffChain Authentication",
          },
        }),
      ],
      transports: {
        [mainnet.id]: http(),
      },
    })
  }

  async connect(provider) {
    this.#checkNullableConfig()
    return await connect(this.config, { connector: provider })
  }

  async signMessage({ message, account, connector }) {
  
    this.#checkNullableConfig()
    return await signMessage(this.config, {
      message,
      account,
      connector,
    })
  }

  disconnect() {
    this.#checkNullableConfig()
    return disconnect(this.config)
  }

  async reconnect() {
    this.#checkNullableConfig()
    return await reconnect(this.config)
  }

  getConnections() {
    this.#checkNullableConfig()
    return getConnections(this.config)
  }

  getConnectors() {
    this.#checkNullableConfig()
    return getConnectors(this.config)
  }

  #checkNullableConfig() {
    assert(this.config, "config is null")
  }
}

const assert = (condition, errorMsg) => {
  if (!condition) {
    throw new Error(errorMsg)
  }
}

const web3ConnectionProvider = () => {
  const provider = new Web3ConnectionProvider()
  provider.init()
  return provider
}

export const web3Provider = web3ConnectionProvider()
