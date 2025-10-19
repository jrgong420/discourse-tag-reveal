Note: Before I post this in theme components, I wanted to get some feedback first if this theme component qualifies or if there are any major issues with it.

> Disclosure: This theme component was planned, implemented, and tested with the help of AI coding tools.

Would love to hear your feedback!

---

|                      |                              |                                                                                                                             |
| -------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| :information_source: | **Summary**                  | Tag Reveal                                                                                                                  |
| :eyeglasses:         | **Preview**                  | Not available...                                                                                                            |
| :hammer_and_wrench:  | **Repository**               | https://github.com/jrgong420/discourse-tag-reveal                                                                           |
| :question:           | **Install Guide**            | [How to install a theme or theme component](https://meta.discourse.org/t/how-do-i-install-a-theme-or-theme-component/63682) |
| :open_book:          | **New to Discourse Themes?** | [Beginner's guide to using Discourse Themes](https://meta.discourse.org/t/beginners-guide-to-using-discourse-themes/91966)  |

Discourse Tag Reveal is a lightweight theme component that keeps topic lists tidy by showing only the first N tags per topic and replacing the rest with an accessible "+X more tags" toggle. Users can expand to see all tags and collapse back to the shortened view. It works out of the box with Discourse’s standard tag UI and requires no server-side changes.

## Features

- Configurable tag limit (default: 5) via theme settings
- Toggle styled as a tag, keyboard accessible (Enter/Space) with ARIA attributes
- Localized strings using themePrefix and discourse-i18n
- SPA-safe behavior: resets and re-applies logic on page changes
- Supports infinite scrolling via MutationObserver
- Minimal CSS; respects core tag styles
- No template overrides or plugin dependencies

## Screenshots / Demo

....coming soon

## Installation & Configuration

- Tested with Discourse version: 3.6.0beta1
- Configure settings under the component’s Settings tab:
  - `max_tags_visible` (integer, default 5): How many tags to show before collapsing
  - `toggle_tag_style` : Visual style of the toggle to match tag appearance (Currently only "box" style implemented)
- Scope: affects topic lists (Latest, New, Unread, and category topic lists)

## Compatibility with other Theme Components

:warning: Only minimal tests performed, please test yourself before deploying to production

- [Topic Cards](https://meta.discourse.org/t/topic-cards/296048) :white_check_mark:

## Notes

- Ensure tagging is enabled (Admin → Settings → Tags), otherwise you won’t see any effect
- If your site heavily customizes tag CSS, you may want to tweak `.ts-toggle` styles for perfect visual alignment

## Ideas for the future

I don't really plan to implement more features but I'm happy to accept PRs. Some ideas for the future:

- Enable/disable for tags in topic view
- Granular control for specific pages and/or categories
