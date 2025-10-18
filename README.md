# Tag Reveal

A Discourse theme component that shortens long tag lists in topic lists by showing only the first N tags and adding an accessible "+X more tags" toggle. Users can expand to see all tags and collapse back to the shortened view.

## Key Features
- Limits the number of visible tags per topic row (configurable via theme setting)
- Adds an accessible toggle styled like a tag (keyboard and screen-reader friendly)
- Localized UI text (uses themePrefix and `discourse-i18n`)
- Works across discovery/category topic lists and with infinite scrolling
- Minimal CSS that respects Discourse’s existing tag styles
- No server-side changes; pure theme component

## How It Works (Technical Overview)
- JavaScript initializer (`javascripts/discourse/api-initializers/tag-reveal.gjs`):
  - On page change, resets prior processing and re-applies truncation logic
  - Finds `.discourse-tags` within each `.topic-list-item, .latest-topic-list-item`
  - Hides tags beyond the configured limit by applying a `ts-hidden` class
  - Inserts a toggle element (`a.discourse-tag.ts-toggle`) after the last visible tag
  - Toggle switches between:
    - Collapsed: shows first N tags, text is "+X more tags"
    - Expanded: shows all tags, text is "hide"
  - Observes DOM changes (MutationObserver) to handle infinite scrolling
- SCSS (`common/common.scss`):
  - Defines `.ts-hidden` for hiding overflow tags
  - Styles `.discourse-tag.ts-toggle` to look like a tag with hover/focus states
- Translations (`locales/en.yml`):
  - `js.tag_reveal.more_tags`: "+%{count} more tags"
  - `js.tag_reveal.hide`: "hide"
- Theme Settings (`settings.yml`):
  - `max_tags_per_topic` (integer, default 5)
  - `toggle_tag_style` (enum: `box`, default `box`)

## Compatibility
- Minimum Discourse version: 3.6.0 (from `about.json`)
- Discourse features: relies on standard tag UI (`.discourse-tags`). For best results, ensure tagging is enabled (Admin → Settings → Tags).
- Browser compatibility: Uses modern DOM APIs (querySelector, classList, MutationObserver) supported by all evergreen browsers. Matches Discourse’s own support policy.
- Mobile/desktop: Works on both. The component targets topic list pages (Latest, New, Unread, Category topic lists). It doesn’t modify tags inside individual topic pages.

## Installation

### Install via Admin Panel
1. Log in as an admin and go to Admin → Customize → Themes
2. Click "Install" → "From a git repository"
3. Paste the repo URL: `https://github.com/jrgong420/discourse-tag-reveal`
4. Choose "Install". Ensure this is added as a Component (not a full theme)
5. Add the component to the active theme (if not auto-added)
6. Click the component, open the Settings tab, and configure as needed

### Install from GitHub (direct link)
- Repository: https://github.com/jrgong420/discourse-tag-reveal
- This component follows Discourse’s theme component structure and can be installed directly in Admin as above.

### Required/Optional Configuration
- Theme Settings (Admin → Customize → Themes → Tag Reveal → Settings):
  - `max_tags_per_topic`: Maximum number of tags to show before collapsing
  - `toggle_tag_style`: Visual style for the toggle (currently `box` to match tag appearance)

## Usage
- No template changes required. Once installed and enabled, topic lists automatically show only the first N tags.
- Clicking the "+X more tags" toggle expands to reveal all tags; clicking "hide" collapses again.
- Adjust the limit anytime via the theme setting.

## Screenshots
- Desktop: Add `screenshots/desktop.png`
- Mobile: Add `screenshots/mobile.png`

## Development Notes
- Uses modern Discourse theme patterns: `apiInitializer`, `discourse-i18n`, themePrefix for translations
- Scoped CSS keeps overrides minimal and aligned with core tag styling
- Resilient to SPA navigation and infinite scroll via `api.onPageChange` + `MutationObserver`

## License
- MIT — see [LICENSE](./LICENSE)

## Links
- About/Repo: https://github.com/jrgong420/discourse-tag-reveal
- Discourse install guide: https://meta.discourse.org/t/how-do-i-install-a-theme-or-theme-component/63682
