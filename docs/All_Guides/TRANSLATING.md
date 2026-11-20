# Translating RubyMT5 docs

> The docs are internationalised with **[mkdocs-static-i18n](https://github.com/ultrabug/mkdocs-static-i18n)** (suffix structure). English is the source; **27 target languages** are configured. This page is the skeleton for translators.

---

## How it works (the mechanism)

* **Language switcher** — the globe menu in the header lists every configured language; it's generated automatically from the plugin config in `mkdocs.yml`.
* **Fallback** — a page with no translation falls back to **English**, so every language already works end-to-end. You translate pages one at a time; nothing breaks in the meantime.
* **URLs** — English is at the root (`/RubyMT5/…`), each language under its locale (`/RubyMT5/zh/…`, `/RubyMT5/ja/…`, …).

> You **don't** pre-create blank files for every page — that would hide the English fallback behind empty pages. Create a translation file only when you actually translate that page.

---

## How to translate a page

Suffix structure: put the translation **next to** the English file, with the locale before `.md`.

```
docs/All_Guides/GETTING_STARTED.md        # English (source)
docs/All_Guides/GETTING_STARTED.zh.md     # 简体中文
docs/All_Guides/GETTING_STARTED.ja.md     # 日本語
docs/index.md                             # English home
docs/index.ja.md                          # 日本語 home
```

Steps:

1. Copy the English `page.md` to `page.<locale>.md`.
2. Translate the prose. **Keep unchanged:** code blocks, Ruby/API names, enum constants (`:SYMBOL_DIGITS`, `TMT5_ORDER_TYPE_BUY`), file paths, links, and front-matter keys (`hide:`, `description:`).
3. Build (`python -m mkdocs build`) or serve (`python -m mkdocs serve`) and check the page under `/<locale>/`.

**Translate in this order** (highest value first): `index` → `All_Guides/GETTING_STARTED` → `MT5_For_Beginners` → `Your_First_Project` → `GLOSSARY` → `RETURN_CODES_REFERENCE`, then the rest. The deep API/method pages (MT5Account / MT5Service / MT5Sugar) are read mostly in English and can come last.

---

## Right-to-left languages

`ar`, `fa`, `ur`, `he` are right-to-left — with `reconfigure_material: true` the Material theme flips the layout automatically for those locales. Keep code/paths LTR (Markdown handles this).

---

## Language roadmap (27 + English)

| Phase | Locale | Language | Notes |
| ----- | ------ | -------- | ----- |
| — | `en` | English | source (default) |
| 1 | `zh` | 简体中文 | Simplified Chinese |
| 1 | `ja` | 日本語 | |
| 1 | `ko` | 한국어 | |
| 1 | `vi` | Tiếng Việt | |
| 1 | `th` | ไทย | |
| 1 | `id` | Bahasa Indonesia | |
| 2 | `zh-TW` | 繁體中文 | Traditional Chinese |
| 2 | `hi` | हिन्दी | |
| 2 | `ar` | العربية | **RTL** |
| 2 | `ms` | Bahasa Melayu | |
| 2 | `tl` | Filipino | |
| 2 | `tr` | Türkçe | |
| 2 | `fa` | فارسی | **RTL** |
| 2 | `ur` | اردو | **RTL** |
| 2 | `bn` | বাংলা | |
| 2 | `ta` | தமிழ் | |
| 2 | `my` | မြန်မာ | |
| 2 | `km` | ខ្មែរ | |
| 2 | `lo` | ລາວ | |
| 2 | `he` | עברית | **RTL** |
| 3 | `es` | Español | |
| 3 | `pt-BR` | Português (Brasil) | |
| 3 | `ru` | Русский | |
| 3 | `fr` | Français | |
| 3 | `de` | Deutsch | |
| 3 | `it` | Italiano | |
| 3 | `pl` | Polski | |

To add or remove a language, edit the `plugins → i18n → languages` list in `mkdocs.yml`. The switcher and per-locale build update automatically.

---

## Build requirements

```bash
pip install -r requirements-docs.txt   # mkdocs-material + mkdocs-static-i18n
python -m mkdocs serve                 # live preview with the language switcher
```
