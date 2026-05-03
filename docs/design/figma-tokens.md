# Design tokens — pulled from team's Figma file

Source: Figma file `JGUawgfQV6xjWlirhpk73y` → `設計交付 - 元件區` page → `顏色（Color）` frame, fetched 2026-05-03 via Figma REST API. Hex values are exact (not eyeballed).

The deck has 5 color scales × 11 stops + functional aliases.

## Neutral (中性色) — text, borders, surfaces

| Token | Hex | Used as |
|---|---|---|
| `neutral-50` | `#F6F4F0` | Cream card surface |
| `neutral-100` | `#EBE4D6` |  |
| `neutral-200` | `#D6CBB2` |  |
| `neutral-300` | `#BEAA87` |  |
| `neutral-400` | `#AB8F65` |  |
| `neutral-500` | `#9B7D57` |  |
| `neutral-600` | `#846549` | Body emphasis text |
| `neutral-700` | `#6B4F3C` | Muted text on cream |
| `neutral-800` | `#5B4236` | Headings |
| `neutral-900` | `#4E3B32` |  |
| `neutral-950` | `#2C1F1A` | Default text on light bg |

## Base (基本色 — 珍奶咖)

| Token | Hex | Used as |
|---|---|---|
| `base-50` / `base-100` | `#FAF5EC` | **App scaffold background (cream paper)** |
| `base-200` | `#E8CCA0` |  |
| `base-300` | `#DAAA6A` |  |
| `base-400` | `#CE8B41` |  |
| `base-500` | `#B47131` |  |
| `base-600` | `#A45B2A` |  |
| `base-700` | `#834425` |  |
| `base-800` | `#6E3825` | **在哪 logo circle fill (brown, NOT red)** |
| `base-900` | `#5F3024` |  |
| `base-950` | `#361812` |  |

## Primary (主色 — 石磚紅)

| Token | Hex | Used as |
|---|---|---|
| `primary-50` | `#FDF4F4` |  |
| `primary-100` | `#FAE6E6` | Pill/badge bg |
| `primary-200` | `#F6D2D2` |  |
| `primary-300` | `#EFB1B2` |  |
| `primary-400` | `#E48585` |  |
| `primary-500` | `#D65D5D` |  |
| `primary-600` | `#C14141` |  |
| `primary-700` | `#AF3737` | **Primary brand red — buttons, FAB, brand highlights** |
| `primary-800` | `#872D2D` | **Pressed state for primary** |
| `primary-900` | `#712B2B` |  |
| `primary-950` | `#3C1313` |  |

## Secondary (次要色 — 郵筒綠)

| Token | Hex | Used as |
|---|---|---|
| `secondary-50` | `#F3F7F2` |  |
| `secondary-100` | `#E3ECDF` | Chip bg |
| `secondary-200` | `#C5DAC0` |  |
| `secondary-300` | `#8DB687` |  |
| `secondary-400` | `#6D9F68` |  |
| `secondary-500` | `#4C8148` |  |
| `secondary-600` | `#376635` |  |
| `secondary-700` | `#2A522A` | **Postbox green — ZAINA wordmark, signboard frame, success state** |
| `secondary-800` | `#244223` |  |
| `secondary-900` | `#1E361E` |  |
| `secondary-950` | `#101E11` |  |

## Accent (強調色 — 金/橘)

| Token | Hex | Used as |
|---|---|---|
| `accent-50` | `#FDF9ED` |  |
| `accent-100` | `#F9ECCC` |  |
| `accent-200` | `#F4D893` |  |
| `accent-300` | `#EFC569` |  |
| `accent-400` | `#E9A936` | **Sparkle / verified badge / mid accent** |
| `accent-500` | `#E2891E` |  |
| `accent-600` | `#C86817` |  |
| `accent-700` | `#A64A17` |  |
| `accent-800` | `#873A19` |  |
| `accent-900` | `#6F3018` |  |
| `accent-950` | `#401808` |  |

## Functional aliases

- `danger` → primary scale (red doubles as error in this design system)
- `success` → secondary scale (green doubles as success)

## Logo

The 在 / 哪 dual-circle logo:
- Circle fill: `base-800` `#6E3825` (brown, NOT red as initially assumed)
- Circle border: `base-50` `#FAF5EC` (paper cream)
- Character glyphs (在 / 哪): `base-50` `#FAF5EC`
- ZAINA wordmark below: `secondary-700` `#2A522A` (postbox green)

## Components catalogued in deck

From `設計交付 - 元件區` SECTION list (just the component names — wireframe semantics only, not yet pulled with full geometry):

- **Buttons**: 主要按鈕 (Primary-button), 次要按鈕 (Secondary-button), 第三按鈕 (Tertiary-button), 文字按鈕 (Text-button), 功能按鈕 (Function-button), 浮動按鈕 (Float-button), 設定話題按鈕 (topicSelect-button), 登入註冊按鈕 (Signin-button)
- **Tabs / chips**: 頁籤 (Tab), 頁籤物件 (Tab-item), 標籤 (Tag), 夥伴卡的共同話題標籤 (Tag), 徽章 (Badge)
- **Feedback**: 通知訊息 (Toast)
- **Logo / icons**: ZAINA logo, devicon:google, fluent-emoji bubble-tea, weui icons
- **System**: 圓角, 陰影, 邊框, 間距, 文字 (typography), 圖片

The font stack: SF UI Text (iOS), Roboto (Android — the deck uses iOS as primary platform).

## How to refresh this list

```bash
export FIGMA_TOKEN="..."
KEY="JGUawgfQV6xjWlirhpk73y"
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$KEY/nodes?ids=2062:76432&depth=10"
```

The `2062:76432` node id is the `顏色（Color）` frame inside `設計交付 - 元件區`. If page IDs shift in future versions, re-resolve via:

```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$KEY?depth=1"
```
