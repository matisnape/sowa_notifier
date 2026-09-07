# n8n workflow backups

**This directory is the home for every n8n workflow belonging to this notifier.** Export and commit
here after any change worth keeping — see "Refreshing this backup" at the bottom.

## TL;DR

`sowa-notifier-wbpicak.json` is an importable export of the Telegram bot that announces new books
from the Poznań public library. It reproduces the Elixir logic in this repo's `lib/`, which is why
it lives here rather than in a generic tooling repo. **The bot token is redacted** — after importing
you must paste it back into one node, then click **Publish**. Importing alone changes nothing in
production.

## Glossary

Assume no prior context:

- **n8n** — a self-hosted workflow automation tool. A workflow is a graph of *nodes*; the instance
  runs them on a schedule.
- **WBPiCAK** — Wojewódzka Biblioteka Publiczna i Centrum Animacji Kultury, the public library in
  Poznań whose new-arrivals page this bot scrapes.
- **Telegram Bot API** — the HTTP API a Telegram bot talks to. Its auth token *is* the bot: whoever
  holds it can post and delete in the bot's channels.
- **Credential** — n8n's encrypted secret store. Credentials are referenced by id, and their values
  are never exported, so they are safe in a backup.
- **Static data** — a small JSON blob n8n persists per workflow, used here to remember which posts
  are still waiting for a cover. Runtime state, not configuration.
- **Draft vs published** — n8n 2.x keeps two copies of a workflow. Saving edits the *draft* and does
  nothing to production; only **Publish** promotes the draft to the live version.

## What the workflow does

Every 5 minutes during library opening hours it scrapes the new-arrivals page, drops books it has
already announced, and posts each new one to a Telegram channel.

The interesting part is covers. The catalogue often adds a cover image hours or days after the book
appears. A book announced without one is posted as a **photo carrying a grey "Brak okładki"
placeholder**, and a later run swaps that placeholder for the real cover **in place**, so the post
keeps its original date and its position in the feed.

The placeholder is not decoration. Telegram's `editMessageMedia` only works on a message that
already carries media, and a text message can never become a photo message. Without the placeholder
there would be nothing to edit, and the only repair would be delete-and-repost, which always yields
a new date at the bottom of the channel.

## Files

| File | What it is |
|------|-----------|
| `sowa-notifier-wbpicak.json` | The workflow, importable into n8n. Token redacted. |

Source instance: workflow id `Ocv6o6xODE67AKZD`. Exported 2026-09-07 from published version
"Document in-place cover edit".

## How to restore

1. In n8n choose **Import from File** and pick `sowa-notifier-wbpicak.json`.
2. Create or select a **Telegram API** credential, then reattach it on all three nodes that use one:
   `Telegram: z okladka`, `Telegram: bez okladki`, `Ostrzez: zero rekordow`. Credential ids do not
   survive a move between instances.
3. Open the node **`Retry: edytuj okladke`** and replace `__PASTE_BOT_TOKEN_HERE__` in the URL with
   the bot token. The finished URL reads
   `https://api.telegram.org/bot<TOKEN>/editMessageMedia`.
4. Point **Settings → Error workflow** at the alerting workflow, if you also restored it.
5. Click **Publish**, then confirm `activeVersionId` equals `versionId` on
   `GET /rest/workflows/<id>`. Without this step nothing runs.

## Deliberately not in this backup

- **The bot token.** Git history is permanent, so a secret committed once stays recoverable even
  after deletion. Get the token from BotFather (`/mybots` → the bot → `API Token`); n8n masks the
  stored value in both the UI and the API.
- **Static data.** It holds message ids of posts still waiting for a cover. Restoring stale ids into
  a different channel would make the bot edit unrelated messages.
- **Credential values.** Referenced by id only, which is why step 2 exists.
- **The alerting workflow** (`SowaNotifier WBPiCAK - failure alerts`, id `RgaekiE93myMWYx1`). Not
  exported here; `settings.errorWorkflow` still points at its id.

## Gotchas that will bite on restore

1. **Saving is not publishing.** This cost four days once: 45 draft saves sat unpublished while
   production kept running a stale graph, silently losing books. Check
   `activeVersionId == versionId`, never the canvas.
2. **Global static data lives under `staticData.global`.** `$getWorkflowStaticData('global')` reads
   that key. Writing at the top level of `staticData` fails silently — the Code node reads an empty
   object and no error appears anywhere.
3. **The placeholder is a Telegram `file_id`, not a URL.** It was produced by uploading the image
   once; the id is hardcoded in `Telegram: bez okladki`. A `file_id` is valid only for the bot that
   uploaded it, so a **new bot token means uploading a new placeholder** and replacing that id.
4. **Static data persists only on production executions.** A manual run records nothing, so the
   retry branch cannot be tested by clicking Execute.
5. **The Error Trigger fires only on automatic executions.** Alerting cannot be verified by hand.

## Refreshing this backup

Export again after any change worth keeping, and redact before committing:

```sh
# from the n8n UI: workflow menu -> Download
python3 - <<'EOF'
import json, re, pathlib
p = pathlib.Path("sowa-notifier-wbpicak.json")
d = json.loads(p.read_text())
d.pop("staticData", None)
d.pop("pinData", None)
s = re.sub(r"/bot\d{6,}:[A-Za-z0-9_-]{20,}/", "/bot__PASTE_BOT_TOKEN_HERE__/", json.dumps(d, ensure_ascii=False, indent=2))
p.write_text(s + "\n")
EOF
grep -nE '[0-9]{6,}:[A-Za-z0-9_-]{20,}' sowa-notifier-wbpicak.json && echo "TOKEN STILL PRESENT - do not commit"
```

The `grep` must print nothing. Treat any output as a blocker.
