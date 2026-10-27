# Privacy Policy — iris-whatsapp-adapter

_Last updated: 2026-10-26_

iris-whatsapp-adapter is an open-source package that connects an InterSystems IRIS
instance to the WhatsApp Cloud API (Meta). It is software you install and run yourself;
it does not include or rely on any service operated by the author.

## Who is responsible

Juan Mota Sanchez ([xJuan21](https://github.com/xJuan21) on GitHub). Contact:
[open an issue](https://github.com/xJuan21/iris-whatsapp-adapter/issues) in this repository.

For data processed by a running installation, the **operator** of that IRIS instance
is responsible (see [TERMS.md](TERMS.md)).

## What data is processed

When the adapter is used:

- **Incoming messages** (webhook from Meta): sender phone number (WhatsApp ID),
  sender profile name, message ID, message type, message text, and timestamp.
- **Outgoing messages**: recipient phone number and message content (text or
  template name and parameters), and the message ID Meta returns.
- **Delivery status updates**: message ID, recipient, and error code when a
  delivery fails.

## Where the data goes

- Data is stored **only in the operator's own IRIS instance**, as Interoperability
  messages and Event Log entries.
- Messages travel between that instance and **Meta's WhatsApp Cloud API**, which
  delivers them. Meta's handling is governed by Meta's own terms and privacy policy.
- The author receives **no data** from any installation. The package has no
  servers, analytics, or tracking.

## Sharing

No data is sold or shared with third parties by this software. Operators may route
messages to other systems through their own production configuration; that is
their decision and responsibility.

## Retention and deletion

Data is kept until the operator deletes it. To delete data:

- **Messages**: purge Interoperability messages (Management Portal →
  Interoperability → Manage → Purge Management Data), or
- **Everything**: uninstall the package and delete the namespace and its databases.

If you exchanged WhatsApp messages with an installation and want your data deleted,
contact the **operator** of that installation. For questions about this policy,
[open an issue](https://github.com/xJuan21/iris-whatsapp-adapter/issues); please don't
include personal data such as phone numbers in it, since issues are public.

## Changes

Changes to this policy are made in this repository; its history shows every revision.
