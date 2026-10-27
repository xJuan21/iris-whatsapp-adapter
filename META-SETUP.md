# Meta setup for iris-whatsapp-adapter

Everything you need on Meta's side, in order. The IRIS side is in the [README](README.md).

Meta changes its dashboard often. Menu names below match the **"use cases"** layout as
of October 2026; if yours differs, look for the same names nearby.

## What you'll end up with

| Item | Where it goes in IRIS | Secret? |
|---|---|---|
| Access token | `SetToken(...)` | **Yes** |
| Phone Number ID | System Default Setting `PhoneNumberId` | No |
| WhatsApp Business Account ID | `SubscribeApp(...)` | No |
| App Secret | `SetSecrets(..., "<App Secret>")` | **Yes** |
| Verify token (you invent it) | `SetSecrets("<verify token>", ...)` and Meta's webhook form | **Yes** |

Two IDs look alike but are different: the **Phone Number ID** identifies the sending number;
the **WhatsApp Business Account (WABA) ID** identifies the business account that owns it.

## 1. Create the app

1. Go to [developers.facebook.com](https://developers.facebook.com) → **My Apps** → **Create app**.
2. Choose the use case **Connect with customers through WhatsApp**.
3. Name the app. Meta rejects names containing "WhatsApp".
4. Pick or create a **business portfolio** when asked. It doesn't need to be verified.

## 2. Get a test number and send a first message

Use cases → **Customize** → **Step 1. Try it out** (also called API Setup).

1. Meta gives you a free **test phone number**. Note its **Phone Number ID** and the
   **WhatsApp Business Account ID** shown on the same page.
2. Under **To**, add your own phone number as a recipient and confirm the code Meta
   sends you. The test number can only message numbers on this list (up to 5).
3. Click **Send message**. You should receive the `hello_world` template.

## 3. Get an access token that lasts

The token on the API Setup page is a **short-lived user token: it expires in 1–2 hours**,
and generating a new one can invalidate the previous one. Pick one:

| Option | Lifetime | How |
|---|---|---|
| Extend it | ~60 days | Paste the token into the [Access Token Debugger](https://developers.facebook.com/tools/debug/accesstoken/) → **Extend Access Token** |
| System User token | Doesn't expire | business.facebook.com → Settings → Users → **System users** → add an admin → assign your app and WhatsApp account → **Generate token** with `whatsapp_business_messaging` and `whatsapp_business_management` |

For a demo, extending is enough. For anything long-running, use a System User token.
Store it in IRIS with `SetToken` (README step 1). The API Setup page will keep saying
"Not generated yet": that's normal, Meta never shows a token twice.

## 4. App Secret

App settings → **Basic** → **App secret** → **Show** (asks for your password).
Store it with `SetSecrets` (README step 4). It proves each webhook call really comes from Meta.

## 5. Register the webhook

You need a public HTTPS URL that reaches IRIS (README step 5 creates the endpoint).

Use cases → Customize → **Step 2. Production setup** → **Configure Webhooks**:

| Field | Value |
|---|---|
| Callback URL | `https://<your public host>/whatsapp/webhook` |
| Verify token | the same string you gave `SetSecrets` |

Click **Verify and save**. Meta calls the URL once to check the token; the production must
be running.

Then, under **Webhook fields**, make sure **`messages`** is **Subscribed**. Meta may
auto-subscribe a few others (`account_alerts`, `account_update`, ...); the adapter ignores
them, so you can unsubscribe them to reduce noise.

In Step 2, **skip** "Register your WhatsApp phone number" and "Add payment" if you're
staying on the test number.

## 6. Publish the app

While the app is **unpublished**, Meta only delivers the dashboard's **Test** webhooks.
Real messages from phones, even yours as the admin, are **not delivered**.

1. App settings → **Basic**, fill in:

   | Field | Value |
   |---|---|
   | Privacy policy URL | required, e.g. this repo's [PRIVACY.md](PRIVACY.md) |
   | Terms of Service URL | e.g. [TERMS.md](TERMS.md) |
   | User data deletion | "Data deletion instructions URL" → e.g. `PRIVACY.md#retention-and-deletion` |
   | App icon | 1024 × 1024, no Meta or WhatsApp logos |
   | Category | e.g. Utility & productivity |

   **Save changes.**
2. Left menu → **Publish** → check that all requirements are met → **Publish**.

With the WhatsApp permissions at standard access ("Ready for testing"), no App Review or
business verification was needed to publish an app that works with your own account.

## 7. Subscribe your app to your WhatsApp Business Account

**Easy to miss, and nothing in the dashboard tells you.**

Registering the webhook (step 5) tells Meta *where to send this app's events*. It doesn't
tell your **WhatsApp Business Account** to *send its events to this app*. That link is a
separate list on the WABA, `subscribed_apps`. Meta's full onboarding creates it for you;
the test-number path doesn't.

The symptom: the dashboard **Test** button reaches IRIS, but real messages never do. The
Test button works because it uses Meta's own internal app ("WA DevX Webhook Events 1P
App"), which is subscribed.

Fix it from IRIS (uses the stored token, never displays it):

```objectscript
Write $System.Status.GetErrorText(##class(WhatsAppMeta.Util.Setup).SubscribeApp("<WhatsApp Business Account ID>"))
```

It prints the subscribed apps afterwards: your app should be listed. To check later:
`ListSubscribedApps("<WhatsApp Business Account ID>")`.

## 8. Things to know

- **24-hour window.** Free-form text (`SendTextRequest`) is only delivered within 24 hours
  of the user's last message to you. Outside it, Meta accepts the request and reports the
  failure later (error `131047`, logged as a warning). Templates work any time.
- **Test number limits.** Only numbers in the **To** list can receive messages
  (otherwise error `131030`).
- **API version.** The adapter defaults to Graph API `v26.0`, the version Meta's dashboard
  showed in October 2026. Change the `ApiVersion` setting if Meta retires it.
