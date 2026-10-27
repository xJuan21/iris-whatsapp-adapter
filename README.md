[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

# iris-whatsapp-adapter

Send and receive WhatsApp messages from InterSystems IRIS Interoperability productions,
through Meta's official **WhatsApp Cloud API**.

It provides an **outbound adapter and Business Operation** to send messages, and an
**inbound adapter and Business Service** to receive them through Meta's webhook, plus a
small demo production that echoes back whatever you send it.

Implements the InterSystems idea
[DPI-I-882 — Introduce a WhatsApp adapter for IRIS Interoperability](https://ideas.intersystems.com/ideas/DPI-I-882).

## How it works

```
Your production ──▶ Operation.SendMessage ──▶ Adapter.Outbound ──▶ Meta Cloud API ──▶ phone
                                                                                        │
phone ──▶ Meta webhook ──▶ HTTPS ──▶ /whatsapp (API.Webhook) ──▶ Service.Webhook ──▶ your targets
                                     checks X-Hub-Signature-256
```

- **Outbound**: send a `SendTextRequest` or `SendTemplateRequest` to the operation; you get
  back a `SendResponse` with Meta's message ID.
- **Inbound**: Meta posts each message to the `/whatsapp/webhook` endpoint. Requests without
  a valid signature from your Meta App Secret are rejected with `403`. Valid messages become
  `Message.Inbound` requests sent to the targets you choose.

## Requirements

- InterSystems IRIS or IRIS for Health with Interoperability, 2024.1 or later
  (tested on IRIS Community 2026.1)
- IPM (ZPM) package manager
- A Meta developer app with the WhatsApp use case and a phone number (Meta's free test
  number works). See **[META-SETUP.md](META-SETUP.md)** for the Meta side, step by step.
- Inbound only: a public HTTPS URL that reaches your IRIS web server (a reverse proxy or a
  tunnel such as Tailscale Funnel)

## Install

In an Interoperability-enabled namespace:

```objectscript
zpm "install iris-whatsapp-adapter"
```

Or from a clone of this repository:

```objectscript
zpm "load /path/to/iris-whatsapp-adapter"
```

Installing creates only the outbound SSL configuration (`WhatsApp`) and prints the next
steps. It **never** creates the public webhook endpoint by itself (see step 4 below).

## Configure

Run these in the namespace where you installed the package. Each command prints nothing
on success; secrets are stored as Interoperability Credentials, never in code.

**1. Access token** (from Meta, see [META-SETUP.md](META-SETUP.md))

```objectscript
Write $System.Status.GetErrorText(##class(WhatsAppMeta.Util.Setup).SetToken("<access token>"))
```

**2. Phone Number ID**: add a **System Default Setting** (Interoperability → Configure →
System Default Settings → New) so it survives recompiling the production:

| Field | Value |
|---|---|
| Production Name | `WhatsAppMeta.Production.Demo` (or your production) |
| Item Name / Host Class Name | `WhatsAppMeta.Operation.SendMessage` |
| Setting Name | `PhoneNumberId` |
| Setting Value | your Phone Number ID (not the phone number itself) |

**3. Try sending.** Start `WhatsAppMeta.Production.Demo`, then:

```objectscript
Do ##class(WhatsAppMeta.Util.Setup).SendHello("<your number, digits only>")
```

You should receive Meta's `hello_world` template. Sending works now; steps 4–6 are only
needed to **receive** messages.

**4. Webhook secrets**: a verify token you invent, and your Meta App Secret:

```objectscript
Write $System.Status.GetErrorText(##class(WhatsAppMeta.Util.Setup).SetSecrets("<verify token>","<App Secret>"))
```

**5. Create the webhook endpoint.** This creates an **unauthenticated** web application,
so it shows you exactly what it will change and asks before doing anything:

```objectscript
Write $System.Status.GetErrorText(##class(WhatsAppMeta.Util.Setup).CreateWebApp())
```

It creates the web application `/whatsapp` and a role, `WhatsAppWebhook`, whose resources
are looked up from your namespace's own databases. Answer `y` to apply. To undo it, run
`RemoveWebApp()`.

**6. Connect Meta to the endpoint**: register the webhook URL in Meta, then subscribe your
app to your WhatsApp Business Account:

```objectscript
Write $System.Status.GetErrorText(##class(WhatsAppMeta.Util.Setup).SubscribeApp("<WhatsApp Business Account ID>"))
```

Without this last step, Meta's dashboard **Test** button works but real messages never
arrive. [META-SETUP.md](META-SETUP.md) explains why.

**Done.** Message the number from your phone: the demo production replies `Echo: <your text>`.

## Use it in your own production

**Send**: add `WhatsAppMeta.Operation.SendMessage` to your production and send it either
request:

```objectscript
Set Request = ##class(WhatsAppMeta.Message.SendTextRequest).%New()
Set Request.ToRecipient = "15551234567", Request.Body = "Your order has shipped"
```

| Request | Use for |
|---|---|
| `Message.SendTextRequest` | Free-form text. Only allowed within **24 hours** of the user's last message to you |
| `Message.SendTemplateRequest` | Pre-approved templates (`TemplateName`, `LanguageCode`, `BodyParameters`). Can start a conversation at any time |

**Receive**: add `WhatsAppMeta.Service.Webhook` with **Pool Size 0** (web requests drive it),
set its adapter's `VerifyTokenCredentials` / `AppSecretCredentials`, and point
`TargetConfigNames` at your process. It sends one `Message.Inbound` per message
(`FromSender`, `ContactName`, `MessageType`, `Body`, `MessageId`, `SentAt`).

## Classes

| Class | Role |
|---|---|
| `WhatsAppMeta.Adapter.Outbound` | Calls the Graph API; settings `PhoneNumberId`, `ApiVersion` (default `v26.0`), `TokenCredentials` |
| `WhatsAppMeta.Operation.SendMessage` | Business Operation for the two send requests |
| `WhatsAppMeta.Adapter.Inbound` | Verifies the webhook handshake token and `X-Hub-Signature-256` |
| `WhatsAppMeta.API.Webhook` | REST endpoint Meta calls (`GET`/`POST /webhook`) |
| `WhatsAppMeta.Service.Webhook` | Business Service: one `Message.Inbound` per received message; logs failed delivery statuses as warnings |
| `WhatsAppMeta.Process.Echo` | Demo process: replies "Echo: …" |
| `WhatsAppMeta.Production.Demo` | Demo production: webhook → Echo → SendMessage |
| `WhatsAppMeta.Util.Setup` | `SetToken`, `SetSecrets`, `CreateWebApp`, `RemoveWebApp`, `SubscribeApp`, `ListSubscribedApps`, `SendHello` |

## Security

- **Only the webhook should be public.** Expose `/whatsapp` alone, never the whole web
  server; the Management Portal must not be reachable from the internet.
- **Every POST must be signed** by Meta with your App Secret; anything else gets `403`
  before reaching your production. The handshake (`GET`) needs your verify token.
- **The endpoint is unauthenticated** because Meta can't log in. It runs with the
  `WhatsAppWebhook` role only. That role needs read access to the database holding
  credential passwords and to `%Ens_Credentials`, so code running under `/whatsapp` could
  read every credential in the namespace. Only this package's dispatch class runs there.
- If a granted resource also protects other databases, `CreateWebApp()` warns you before
  you agree.
- Secrets live in Interoperability Credentials. Never put them in code, files, or settings.

## Tests

Offline unit tests cover the signature and verify-token checks and the outbound payloads:

```objectscript
zpm "test iris-whatsapp-adapter"
```

To run them from VS Code's Testing panel instead, set the test root once per namespace:

```objectscript
Set Dir = "/durable/irissys/unittestroot/" Write ##class(%File).CreateDirectoryChain(Dir) Set ^UnitTestRoot = Dir
```

## Troubleshooting

| Symptom | Cause |
|---|---|
| `WhatsApp API error 190` | Access token expired (temporary tokens last 1–2 hours). Store a new one with `SetToken` |
| `WhatsApp API error 100 … Object with ID 'messages'` | `PhoneNumberId` is empty. Set it as a System Default Setting |
| `131030 Recipient phone number not in allowed list` | On the test number, add the recipient in Meta's API Setup |
| Echo accepted but never delivered; warning `131047` | Free-form text outside the 24-hour window. Message the number first, or use a template |
| Dashboard Test reaches IRIS, real messages don't | App not published, or app not subscribed to the WABA (`SubscribeApp`) |
| `403` on every webhook call, nothing in the logs | The web app's role can't read the namespace's databases; re-run `CreateWebApp()` |
| `503` from the webhook | The production isn't running |

## License and policies

[MIT](LICENSE) · [Privacy policy](PRIVACY.md) · [Terms](TERMS.md)

Not affiliated with Meta, WhatsApp, or InterSystems.
