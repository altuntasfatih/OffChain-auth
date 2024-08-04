// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import hooks from "./hooks";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
// let Hooks =
// Hooks.Web3Connect = {
//   mounted() {
//     console.log("Web3Connect hook mounted")
//     this.handleEvent("web3-connect:connect-metamask", ({provider}) => {
//       // Your provider connection logic
//     })
//   }
// }

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2000,
  params: { _csrf_token: csrfToken },
  hooks: { ...hooks }
})

liveSocket.connect()

window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
  reloader.enableServerLogs();
});

window.liveSocket = liveSocket