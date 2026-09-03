# Parsing and message contract for the n8n workflow

## 30-second version

This file is the contract between the `sowa_notifier` repository and the n8n workflow that replaces it. It describes one page to fetch, seven CSS selectors, one rule for extracting the link, one deduplication key, and one message template.

**The one thing to remember:** every selector below was verified against the live page on 3 September 2026 and still works. The page returned 20 records with every field populated, except one book that has no cover image.

The repository stops being an application to deploy. It stays the source of truth for how to read the catalogue page.

## Runtime identifiers

**This document contains no identifiers and no secrets.** Every chat id, workflow id and credential id appears as `${VARIABLE_NAME}`. If you are an agent working from this file, ask the repository owner where the real values live before you assume anything — do not guess, and do not copy values from an old chat transcript.

| Variable | What it is | Where the value comes from |
|---|---|---|
| `${WBPICAK_URL}` | the catalogue's new-arrivals page to scrape | not secret; the address is written out in "Page address" below |
| `${WBPICAK_CHANNEL_ID}` | Telegram channel that receives book notifications, in `-100`-prefixed form | ask the owner; also visible in the n8n Telegram nodes |
| `${SOWA_ADMIN_CHAT_ID}` | the maintainer's private Telegram chat, used for operational warnings only | ask the owner |
| `${TELEGRAM_BOT_TOKEN}` | Telegram Bot API token | **secret** — `op://<vault>/<item>/<field>`, vault not yet recorded |
| `${SOWA_NOTIFIER_WEBHOOK_URL}` | Slack incoming webhook used by the original Elixir app | **secret** — `op://<vault>/<item>/<field>`, vault not yet recorded |
| `${N8N_BASE_URL}` | base address of the n8n instance hosting the workflows | ask the owner |
| `${N8N_WORKFLOW_ID}` | id of the main scraping workflow | ask the owner; visible in the workflow URL |
| `${N8N_ERROR_WORKFLOW_ID}` | id of the alerting workflow wired to `Settings → Error workflow` | ask the owner; visible in the workflow URL |
| `${N8N_TELEGRAM_CREDENTIAL_ID}` | id of the `telegramApi` credential stored inside n8n | ask the owner; n8n stores the token, it never leaves the instance |

Two notes on the secrets:

- **The bot token never appears in this repository, in n8n exports, or in chat.** n8n holds it inside a credential; the workflow refers to that credential by id. Nothing outside n8n needs the token.
- **The 1Password vault names are placeholders.** Fill in the real `op://` paths once the owner confirms which vault holds these items.

The recipient split is deliberate: book notifications go to `${WBPICAK_CHANNEL_ID}`, while the broken-selector warning goes to `${SOWA_ADMIN_CHAT_ID}`. A warning about a stale CSS selector is an operational message for the maintainer, not content for channel readers.

## Glossary

Names and abbreviations a reader may not know:

- **WBPiCAK** — Wojewódzka Biblioteka Publiczna i Centrum Animacji Kultury, the regional public library in Poznań, Poland. It owns the catalogue this project scrapes.
- **SOWA** — the library catalogue software the site runs on. The project is named after it.
- **new-arrivals page** — one specific catalogue view listing recently added items. It shows at most 20 records at a time.
- **dziupla** — `dziupla.sowa.pl`, the separate host that serves cover images. Book records link to it, they do not embed the image bytes.
- **Floki** — an Elixir library for parsing HTML, used in the original code. In n8n its place is taken by the HTML node, which is built on cheerio.
- **cheerio** — a JavaScript library for parsing HTML, the engine inside the n8n HTML node.
- **Remove Duplicates** — an n8n node that drops items it has seen before. Its `removeItemsSeenInPreviousExecutions` mode keeps a history across workflow runs.
- **`parser.ex`** — the file `lib/sowa_notifier/parser.ex` in this repository. Source of every selector below.
- **`bot.ex`** — the file `lib/sowa_notifier/telegram/bot.ex`. Source of the message template.

## Overriding principle: n8n reproduces the Elixir logic

The n8n workflow is not a new application. It reproduces behaviour that ran in this repository for a year. **Every departure from the Elixir code must be deliberate and justified, never accidental.**

This is not a theoretical warning. Two accidental departures cost us one broken run:

| Behaviour | Where in Elixir | What n8n did at first | Result |
|---|---|---|---|
| 5-second gap between books | `lib/sowa_notifier.ex:45` and `:61` | 2-second gap | a number invented instead of copied |
| only successfully sent items reach the state file | `lib/sowa_notifier.ex:16-19` | deduplication records the link **before** sending | every failed send permanently lost a book |

One departure is deliberate and is documented below: **the workflow has no delay between messages at all.** See "Deliberate departure: no delay between messages".

A third fact confirms the architecture is the same: Elixir does **not** download the image either. It puts the cover address into the message block (`lib/sowa_notifier/slack/helpers.ex:33`, `image_url: book.img`) and lets the recipient fetch it. The difference is on the recipient side, not ours: Slack silently omits a cover it cannot fetch, while Telegram rejects the whole API call with a `400` error.

Practical rule: before you change a number, an order, or a condition in the workflow, check whether an equivalent exists in `lib/`. If it does, follow it. If you deliberately depart from it, write down why — here and in the sticky note on the canvas.

## Decisions taken

| Topic | Decision |
|---|---|
| opening hours | Monday to Friday 09:00 to 19:00, Saturday 08:00 to 15:30, Sunday closed, timezone `Europe/Warsaw` |
| recipient | the production wbpicak channel, with no separate private test chat |
| cap per run | none — every new book is its own notification, with no batching |
| message language | Polish, with no run-timestamp line |
| date extraction | regex `\d{2}\.\d{2}\.\d{4}`, falling back to the third word |
| `available` field | a boolean, without the detour through Slack emoji codes (`:x:` and `:white_check_mark:` from `bot.ex:61`) |

The opening-hours gate replaces the commented-out cron entry at `config/config.exs:21`, an earlier idea of "Monday to Saturday, 8 to 19". The new hours separate Saturday from weekdays and close Sunday properly.

## Known debt: node names stay in Polish

Every artifact in this project is written in English. The n8n node names are the deliberate exception. They stay in Polish for now.

**Reason:** n8n expressions reference nodes by name as a plain string. Renaming a node during testing can break connections in a way that only surfaces in production. The rename happens in one pass after publication, not before.

## Page address

```
https://katalog.wbp.poznan.pl/index.php?KatID=2&typ=repl&plnk=nowosci&sort=dat
```

Method GET, no authentication, no session parameters. The original code sent the header `user-agent: SowaNotifier Bot` (`lib/sowa_notifier/api.ex:4`) and that is worth keeping, so the library can see who is knocking.

Measured on 3 September 2026: `http_code=200`, 812,278 bytes, which is 793 KB. The response arrives whole, without streaming. Set the response format on the HTTP Request node to text, not JSON.

The address has no parameter controlling the result count. The page returns 20 records and that is the ceiling for a single fetch.

## Selectors

The "source" column gives the line number in `parser.ex`. The "rule" column says what to do with the matched node.

| Field | CSS selector | Rule | Source |
|---|---|---|---|
| — (container) | `.record-details` | one node per book; every selector below works inside it | `parser.ex:7` |
| `title` | `.desc-o-title` | node text, runs of whitespace collapsed to a single space, trimmed | `parser.ex:19` |
| `publisher` | `.desc-o-publ` | as above | `parser.ex:20` |
| `link` | `.record-thumb-with-av div[onclick]` | take the `onclick` attribute of the first match, then apply the regex below | `parser.ex:47` |
| `img` | `.record-thumb-with-av img` | take the `src` attribute, prepend `https:` | `parser.ex:74` |
| `added_on` | `.desc-header` | node text, split on whitespace, take the element at index 2 | `parser.ex:55` |
| `available` | `.record-av-available` | the node being present means "available", absent means "not available" | `parser.ex:38` |
| `queue` | `.opacit-queue` | node text, **optional field** — see the section below | absent from `parser.ex` |

### Waiting-queue length — an optional field

`parser.ex` does not know this field. It was found directly in the new-arrivals page, not in a record subpage, so it **costs no extra request**.

Selector: `.opacit-queue`. The exact text inside the node:

```
Długość kolejki oczekujących: 1
```

The number at the end differs per book. In the 3 September 2026 sample the values ranged from 1 to 15.

Distribution measured on that same page:

- 15 of 20 books carry the field
- no book carries it more than once
- the 5 books without it are exactly those whose copies are available, where a queue makes no sense

**An empty field leaves no trace.** When the node is absent, the message ends on the `Status:` line — no separator, no heading, no "no data" placeholder.

### Rule for extracting the link from onclick

The `onclick` attribute looks like this:

```
location.href='https://katalog.wbp.poznan.pl/index.php?KatID=2&typ=record&001=POZN+W26003237'
```

Take the first capture group with this expression (`parser.ex:66`):

```
location\.href='([^']+)'
```

In the raw HTML the ampersands are written as `&amp;`. The HTML parser decodes them itself. Verified: 20 of 20 links came out with a plain `&`. After building the workflow, confirm this again on the HTML node output, because an `&amp;` inside the link would corrupt the address.

### Date heuristic

The `.desc-header` node currently contains the text `Nowość od: 02.09.2026`. Splitting on whitespace gives three elements:

```
["Nowość", "od:", "02.09.2026"]
```

The date sits at index 2, so it is the third word. The Elixir code counts positions rather than matching words, so a change of site language breaks nothing — but a change in the number of words before the date would. The safer equivalent for n8n is a regex `\d{2}\.\d{2}\.\d{4}` over the whole node text. That is the approach the workflow now uses, with the third-word rule as a fallback.

The date format is `DD.MM.YYYY`. Nothing parses it into a date type; it goes into the message as plain text.

## Deduplication key

The key is **the `link` field alone**. That is how the original works (`lib/sowa_notifier/helpers.ex:39-42`): it builds a set of links already seen and passes through only items missing from it.

Title, publisher, and date take no part in the comparison. The link carries the record identifier (`001=POZN+W26003237`), so it is stable and unique — verified, 20 of 20 links were distinct.

**Remove Duplicates node configuration**, as decided by the author:

- mode: remove items seen in previous executions
- key field: `link`
- history: the default 10,000 entries

The node comment must state that 10,000 is an **entry counter, not a time window**. At a rate of roughly 3 new books per day (measured: 20 records spread over 4 dates in 7 days) that limit lasts several years.

## Message template

Source: `bot.ex:53-65`. Parse mode: HTML.

```
🆕 <b>Nowa książka dodana {added_on}</b>

<b><a href="{link}">{title}</a></b>
{publisher}
Status: {✅ or ❌}

{queue}          <- only when the field exists
```

The `Status` field takes ✅ when the book is available and ❌ when it is not. The queue line is separated by a blank line and appears **only** when the book carries `.opacit-queue`.

Two real examples from control run 285:

```
🆕 <b>Nowa książka dodana 02.09.2026</b>

<b><a href="...&amp;001=POZN+W26003237">Już ci niosę suknię z welonem / Joanna Szarańska.</a></b>
Poznań : Czwarta Strona, copyright 2026.
Status: ❌

Długość kolejki oczekujących: 1
```

```
🆕 <b>Nowa książka dodana 02.09.2026</b>

<b><a href="...&amp;001=POZN+W26003259">Panny z dobrego domu / Edyta Świętek.</a></b>
Kraków : Mando, © 2026.
Status: ✅
```

### Which Telegram call

The original picks between two calls depending on the cover (`bot.ex:41-45`):

- **cover present** — `sendPhoto` with the address from the `img` field, text goes in as `caption`
- **no cover** — `sendMessage`, text goes in as the body

Measured on live data: 19 of 20 books have a cover, so the `sendPhoto` path is the main one.

### Measured lengths

Measured in control run 285, over 20 items, with the queue line already included:

| Measure | Value |
|---|---|
| longest message | 345 characters |
| book with a queue (example above) | 282 characters |
| book without a queue (example above) | 220 characters |
| Telegram limit on `caption` | 1024 characters |
| Telegram limit on message body | 4096 characters |
| limit breaches | 0 |

The headroom against the `caption` limit is almost threefold. Truncation is not needed.

### Three guards in the Code node

Each one throws an error and stops the run, rather than letting a corrupted message out:

1. a raw address in square brackets survived into the finished message, meaning some text field bypasses `unlink()`
2. the message ends with a blank line, meaning an empty optional field left its separator behind
3. the message contains two blank lines in a row

### Warning: no character escaping in the original

Title and publisher go into HTML parse mode with no escaping at all. A title containing `&`, `<`, or `>` breaks Telegram's parsing and the message is rejected.

Verified on the current sample: 0 of 20 items contain those characters. This is a landmine, not an outage — but in n8n it costs one function escaping three characters, so it is worth adding straight away.

A worse case applies to the link itself. Telegram requires `&` to be escaped **inside the `href` attribute** too, and every catalogue link contains two ampersands (`&typ=record&001=`). The original inserts the link raw (`bot.ex:59`), so it relies on Telegram's parser being lenient. In the n8n workflow the link passes through a separate escaping function that turns it into `&amp;`. The `link` field used for deduplication stays raw — only the copy inside the message is escaped.

### Text extraction inserts link addresses

The n8n HTML node with `returnValue: "text"` **inlines the addresses from every `<a href>`** as `[https://...]`. Publisher names in the catalogue are links, so this hits on every single record.

Measured effect: the publisher line grew from `Poznań : Czwarta Strona, copyright 2026.` to `Poznań : Czwarta Strona [https://katalog.wbp.poznan.pl/...], copyright 2026.`, and the longest message grew from 338 to 406 characters.

The fix is a single `unlink()` function in the Code node, applied to **every** text field rather than only the publisher, because the catalogue may link the author or the status next. Guard 1 above exists to catch exactly that recurrence.

## Pace and send limits

The goal is one book, one message, with no grouping.

Numbers that constrain the workflow:

- a single run returns at most **20 items** — that is what the new-arrivals page holds
- the first run against empty state announces all 20 at once, because every one of them is new
- Telegram accepts roughly 30 messages per second globally and roughly 20 per minute into a single group chat
- the original waited 5 seconds between items (`lib/sowa_notifier.ex:45` and `:61`), which is 12 messages per minute

### There is no cap on messages per run

**Decision by the project owner: every book gets its own notification, and nothing is batched or held back.** Neither the repository nor the workflow caps a run.

A Limit node briefly existed in the workflow, set to 10, and was removed. Removing it fixed a defect rather than relaxing a safeguard.

#### Named trap: a limit placed after deduplication destroys the surplus

The Limit node sat **after** `Odsiej juz ogloszone`. Deduplication records a link the moment an item passes through it, so by the time the Limit node cut books 11 and beyond, those books were **already marked as announced**. They were never sent and never came back.

That is the same class of loss the error branch exists to prevent — an item recorded as delivered without any message going out.

The Elixir version had the opposite shape. Its cap kept the surplus **out of the state file**, so the leftovers reappeared on the next run:

| | Where the cap sat | What happened to the surplus |
|---|---|---|
| Elixir (removed) | before the state file was written | stayed unrecorded, went out on the next run |
| n8n (removed) | after deduplication recorded the link | recorded as announced, silently lost |

**The general rule:** a limit, filter, or sampling step placed downstream of anything that writes state is a data-loss bug, not a throttle. If you ever reintroduce a cap, it has to sit **before** deduplication, or deduplication has to record only what was actually delivered.

### Deliberate departure: no delay between messages

Elixir waited 5 seconds between books (`Process.sleep(5000)` at `lib/sowa_notifier.ex:45` and `:61`). **This workflow has no equivalent, on purpose.** A Wait node existed here and was removed.

Two measured reasons:

1. **The n8n Wait node never was a delay between messages.** It pauses the execution once, not once per item. Measured: 10 items on the input, `executionTime` exactly the configured interval, then all 10 continue at once. The author confirmed the same thing independently — two notifications from one run arrived in the same minute.
2. **A real per-item delay would fix a cause that does not exist.** Pace was ruled out by direct experiment; see the cover section below.

A real per-item delay would need a Loop Over Items node with a batch size of 1 and the Wait inside the loop. Build it only if Telegram starts returning `429` or `retry_after`. It returns neither today.

### One cover Telegram will not fetch — pace ruled out

One book in twenty fails on `sendPhoto` with:

```
400 - {"ok":false,"error_code":400,"description":"Bad Request: failed to get HTTP URL content"}
```

The book is `Willa Hössa / Marcin Mościński`, cover `https://dziupla.sowa.pl/f/vwca7mjprrvt2.jpg?imwh=205x300`.

**The file is healthy.** HTTP 200, `image/jpeg`, 12,397 bytes, baseline JPEG, RGB with an sRGB profile, 3 components, 205×300 pixels, decodes cleanly under `djpeg`, ends with the `FFD9` marker. It is indistinguishable from a neighbouring cover that works.

**Neither host shows bot protection.** No `cf-ray`, no `cf-cache-status`, no `cf-mitigated`, no `x-sucuri-id`, nothing from Akamai. The cover host runs `dziupla/0.8.5.1` over HTTP/1.1; the catalogue runs `nginx/1.18.0` over HTTP/2. The cover host returns a byte-identical response to four different user-agents, including one imitating a Telegram bot and the `SowaNotifier Bot` string the Elixir code used.

**Two independent experiments rule out pace:**

- **In-batch control (run 294).** Nineteen cover attempts went out in a single batch and only the fourth failed. Positions 8, 12, 16 and 20 all succeeded. Throttling produces a rising or periodic pattern; this is one point of failure with eighteen successes after it.
- **Sent completely alone (run 296).** A temporary filter reduced the run to this one book. It was the only item in the whole execution, with no batch around it, and it still failed after 120 ms.

**Root cause is unknown.** The error text is the strongest available hint: `failed to get HTTP URL content` describes a failure to *fetch*, not to decode, so inspecting the file can never explain it. Elixir never hit this because Slack silently omits a cover it cannot fetch, while Telegram rejects the whole call.

**The durable answer is the error branch**, not a fix. One book in twenty goes out as plain text instead of a photo, and no book is lost.

## Empty-result guard

Zero items out of the HTML node is a **success** in n8n, not an error. The Error Trigger will not fire. That means a broken selector looks exactly like a quiet day with no new books.

The workflow must therefore tell two situations apart:

- **the HTML node returned zero items** — the page changed or went down, so send a warning
- **Remove Duplicates returned zero items** — the normal state, nothing new, finish quietly

The branch sits after the HTML node, before deduplication. Without this node the workflow is unfinished.

## Failure alerting

### The failure mode this guards against

The dangerous failure of this bot is not a crash. It is silence.

If the library rebuilds the page and `.record-details` stops matching, the HTML node returns zero items, and **the run finishes successfully**. Nothing is wrong from n8n's point of view. The bot goes quiet for weeks while every dashboard shows it as healthy.

### Turning silence into a failure

The false branch of the empty-result guard now ends with a **Stop and Error** node (`Fail the run on zero records`), placed after the warning message.

Order matters: the warning goes out first, then the run is failed deliberately. Without the Stop and Error node the warning message would be the only signal, and no alerting mechanism would ever see it.

### The alert workflow

A separate workflow carries the alerting:

| Property | Value |
|---|---|
| name | `SowaNotifier WBPiCAK - failure alerts` |
| id | `${N8N_ERROR_WORKFLOW_ID}` |
| nodes | Error Trigger → Telegram `sendMessage` |
| recipient | the author's private chat, `${SOWA_ADMIN_CHAT_ID}` |
| credential | a `telegramApi` credential stored in n8n, id `${N8N_TELEGRAM_CREDENTIAL_ID}` |
| active | yes |

The main workflow points at it through `Settings → Error workflow` (`settings.errorWorkflow = ${N8N_ERROR_WORKFLOW_ID}`).

The message is deliberately plain: no `parse_mode`, no HTML, no cover image. It carries the workflow name and id, the node that failed, the error message, the execution id and its link, the execution mode, and a timestamp in `Europe/Warsaw`. It has to be readable at three in the morning.

### Limitation: the Error Trigger cannot be tested by hand

**The Error Trigger fires only on automatic executions that end in an error.** It does not fire on manual runs, and clicking Execute on the alert workflow proves nothing.

So never claim the alerting works on the strength of a manual run. Verifying it for real needs an active workflow and a deliberately induced failure.

## Open questions

One thing remains, on the author's side. The second entry is kept as a resolved record.

1. **Telegram credentials in n8n** — the author enters them. The token goes neither into this file nor into `config/config.exs`.
2. ~~The channel identifier format~~ — **resolved.** The Bot API needs the `-100` prefix in front of the internal channel number, so `${WBPICAK_CHANNEL_ID}` holds the prefixed form. The bare number shown in the `web.telegram.org` URL fragment is not accepted on its own and was never needed. Verified by one message to the production channel: `ok: true`, `chat_type: "channel"`, and a `chat_title` matching the intended channel.

   Rule of thumb when you set this up somewhere new: take the number from the Telegram Web address, prepend `-100`, and confirm with the API response rather than by eye. A successful send returns `chat_type` and `chat_title`, which proves you reached the intended chat and not another one with a similar number.

## Where the numbers come from

All measurements are from 3 September 2026, on a single fetch of the page:

- 20 items, every field populated except `img` on one book
- empty-value distribution: `%{link: 0, title: 0, available: 0, added_on: 0, img: 1, publisher: 0}`
- dates in the sample: 27.08 (7 items), 28.08 (1), 01.09 (7), 02.09 (5)
- response size 812,278 bytes
- 323 bytes per record once written to JSON
