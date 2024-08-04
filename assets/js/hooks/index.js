let Web3Connect = {
  connection: null,
  web3Provider: null,
  async mounted() {
    await this.lazyLoadWeb3Resources();

    this.handleEvent("web3-connect:select-provider", (e) => {
      this.handleConnectWeb3Provider(e);
    });

    this.handleEvent("web3-connect:sign-data",
      async ({ data }) => {
        await this.signData(data);
      }
    );
    this.handleEvent("web3-connect:error", (e) => this.handleConnectError(e));
    this.handleEvent("web3-connect:disconnect-wallet", () => {
      this.disconnectWallet();
    });
  },
  async lazyLoadWeb3Resources() {
    const { web3Provider } = await import("../web3");
    this.web3Provider = web3Provider;
    await this.reconnectIfConnectionExists();
    this.loadProviders();
  },
  loadProviders() {
    this.pushEventTo(this.el, "web3-connect:detected-providers", {
      providers: this.getWeb3WalletExtensions(),
    });
  },

  async reconnected() {
    await this.reconnectIfConnectionExists();
  },
  async connectWallet(provider) {
    try {
      this.connection = await this.web3Provider.connect(provider);
    } catch (error) {
      console.log(error);
      this.sendErrorEvent(error);
    } finally {
      if (this.connection) {
        setTimeout(() => this.sendConnectedMessage(provider), 3000);
      }
    }
  },
  async signData(data) {
    try {
      const signature = await this.web3Provider.signMessage({
        message: data,
        account: this.connection.accounts[0],
        connector: this.connection.connector,
      });
      this.pushEventTo(this.el, "web3-connect:signed-data", {
        signature: signature,
        address: this.connection.accounts[0],
      });
    } catch (error) {
      console.log(error)
      this.sendErrorEvent(error);
    }
  },
  findProvider(providerId) {
    return this.web3Provider
      .getConnectors()
      .find(({ id }) => id === providerId);
  },
  async handleConnectWeb3Provider(event) {
    const { provider: providerId } = event;
    this.connection = this.getExistingConnection(providerId);
    let provider = this.findProvider(providerId);
    if (!provider) {
      this.pushEventTo(this.el, "web3-connect:injected-provider-not-detected", {
        provider: providerId,
      });
      return;
    }

    if (this.connection) {
      this.sendConnectedMessage(provider);
    } else {
      await this.connectWallet(provider);
    }
  },
  sendConnectedMessage(provider) {
    this.pushEventTo(this.el, "web3-connect:connected", {
      provider: {
        id: provider.id,
        address: this.connection.accounts[0],
        is_connected: true,
      },
    });
  },
  handleConnectError(e) {
    this.liveSocket.execJS(this.el, this.el.dataset.showSnackbar);

    setTimeout(() => {
      this.liveSocket.execJS(this.el, this.el.dataset.hideSnackbar);
    }, 1200);
    console.error("connect error received:", e);
  },
  disconnectWallet() {
    if (!this.connection) return;
    this.web3Provider.disconnect();
    this.connection = null;
  },
  sendErrorEvent(error) {
    this.pushEventTo(this.el, "web3-connect:connection-error", { error });
  },
  async reconnectIfConnectionExists() {
    if (this.activeWeb3Connections()) {
      await this.web3Provider.reconnect();
    }
  },
  activeWeb3Connections() {
    return this.getweb3Connections().length !== 0;
  },
  getExistingConnection(providerId) {
    const connections = this.getweb3Connections();
    if (!connections.length) return null;

    return connections.find((conn) => {
      return conn.connector.id === providerId;
    });
  },
  getWeb3WalletExtensions() {
    return this.web3Provider.getConnectors().map(({ id, name, type }) => {
      return { id, name, injected: type === "injected" };
    });
  },
  getweb3Connections() {
    return this.web3Provider.getConnections();
  },
};

export default {
  Web3Connect,
};