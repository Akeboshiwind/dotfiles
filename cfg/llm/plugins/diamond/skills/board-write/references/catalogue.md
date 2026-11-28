# Catalogue JSON

```json
{"title": "Library prior art",
 "subtitle": "optional; defaults to an item and section count",
 "themes": [{"title": "…", "body": "…", "refs": ["M7", "P9"]}],
 "sections": [{"id": "M", "title": "Media-library apps", "note": "optional, shown after the title",
   "items": [
     {"id": "M7", "name": "Castro", "kind": "podcast app", "link": "https://…", "sig": "…", "use": "…",
      "images": [{"file": "img/m7-1.jpg", "caption": "…", "source": "https://…"}]}]}]}
```

| field | required | notes |
|---|---|---|
| `title` | yes | the board's heading |
| `themes[]` | no | `title`, `body`, `refs` (item ids; an unknown id only warns) |
| `sections[].title`, `.items` | yes | one frame per section; `id` and `note` are optional |
| `item.id` | yes | names the card file, lowercased: ids must stay **distinct once lowercased** across the whole catalogue |
| `item.name` | yes | the card's title, shown as `id · name` |
| `item.kind`, `.sig`, `.use` | no | a line each, skipped when empty; `use` is prefixed `Use:` |
| `item.link` | no | the card's Excalidraw link |
| `item.images[]` | no | `file` (required; relative to the root; any format ImageMagick reads, first frame only), `caption`, `source` (kept, not drawn) |

`fetch-images` writes each item's `images` to `OUT/images/<id>.json` as `{"id", "images": [...]}`, with `file` relative to `OUT`; `discover` merges them into the items. So the root is `OUT`.

Text is plain, not Markdown; arrows and kana are fine. Each image is resized to 360px high in its card, so keep to about four images an item.

## Where files go

- **Board:** `VAULT/Excalidraw/<Name>.excalidraw.md`.
- **Cards:** `VAULT/Excalidraw/<Name> cards/<id>.jpg`, beside the board and inside the vault, so Obsidian resolves the board's `[[…]]` embeds.
- **Source images** stay where they are, outside the vault: only the cards enter it.
