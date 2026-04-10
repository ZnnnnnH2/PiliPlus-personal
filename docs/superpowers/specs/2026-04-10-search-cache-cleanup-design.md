# 2026-04-10 Search / Cache Cleanup Design

## Status

- Approved in chat before writing.
- Scope intentionally limited to low-conflict cleanup and performance work.

## Background

The repository is currently in a dirty worktree with many uncommitted edits across player, setting, and HTTP-related files. A broad refactor would carry high merge and regression risk. The requested work is to improve code quality and performance, so this design targets a narrow, measurable slice that is:

- low conflict with existing uncommitted changes
- easy to verify and roll back
- valuable for both maintainability and runtime behavior

The selected scope covers:

- `lib/pages/search/**`
- `lib/utils/cache_manage.dart`
- `lib/pages/about/view.dart`
- `lib/common/widgets/self_sized_horizontal_list.dart`

## Goals

- Reduce unnecessary widget rebuilds in the search page.
- Make search suggestion updates asynchronous-safe so stale responses do not overwrite newer input.
- Reduce blocking file-system work in cache size calculation and cache clearing.
- Clarify responsibilities between controller, page, and utility layers.
- Keep user-visible behavior stable unless the current behavior is obviously incorrect or wasteful.

## Non-Goals

- No migration away from GetX.
- No player, main settings page, or protobuf/generated-code refactor.
- No changes to API contracts or server request parameters.
- No broad HTTP response model cleanup in this round.
- No UI redesign.

## Constraints

- Avoid files that already have extensive local modifications when possible.
- Keep changes isolated and easy to revert by file.
- Prefer small structural cleanup with measurable payoff over large architecture rewrites.

## Design Summary

This round will make three focused improvements:

1. Search flow cleanup
2. Cache IO cleanup
3. Small shared widget stabilization

Each area is designed to stand on its own, but together they improve runtime smoothness and make the touched code easier to reason about.

## 1. Search Flow Cleanup

### Current Issues

- Input handling, request triggering, history persistence, and some display decisions are spread across the controller and page.
- Search suggestion requests can complete out of order.
- Large `Obx` boundaries cause unrelated state changes to rebuild more UI than necessary.
- History writes are not centralized.

### Proposed Structure

`SSearchController` remains the owner of search state and side effects.

Responsibilities:

- normalize text input
- maintain UID-search visibility state
- debounce suggestion requests
- reject stale suggestion responses
- manage history list mutations and persistence
- expose stable reactive state for rendering

`SearchPage` remains a composition layer only.

Responsibilities:

- render the app bar and sections
- route user events into controller methods
- subscribe only to the minimum state required by each visual section

### Request Correctness Strategy

Search suggestions will keep the existing debounce behavior, but a response-validity guard will be added:

- increment a request token before each suggestion request
- capture the token and normalized keyword at request time
- when the response returns, only apply it if:
  - the token still matches the latest issued token
  - the current input still matches the request keyword

This prevents stale network responses from replacing the suggestions for newer input.

### History Management Strategy

History mutations will be centralized in private helpers inside the controller, for example:

- insert a keyword at the front while removing duplicates
- persist the current history list
- replace history from imported data
- remove a single history item
- clear all history

This removes direct persistence logic from the page and makes future testing easier.

### UI Boundary Strategy

The search page will keep its current layout, but rebuild boundaries will be tightened:

- UID button reacts only to `showUidBtn`
- suggestion section reacts only to suggestion state
- history section reacts only to history-related state
- hot/trending blocks react only to their own loading states

This reduces the cost of input-driven updates and keeps widget responsibilities clearer.

## 2. Cache IO Cleanup

### Current Issues

- Cache traversal relies on synchronous listing in recursive code paths.
- Deletion helpers are inconsistent.
- Some async operations are not properly awaited.
- Desktop and mobile paths share behavior but not implementation structure.

### Proposed Structure

Keep the public API surface of `CacheManage` stable, but change internal implementation:

- split cache-size collection into small private helpers by platform/path type
- use asynchronous directory traversal instead of `listSync`
- use explicit helper methods for file deletion and directory deletion
- ensure delete operations are awaited
- avoid unnecessary conversions and duplicate path logic

### Cache Size Strategy

The cache size collector will:

- inspect only the currently relevant cache locations
- iterate file-system entities asynchronously
- sum file sizes directly without string conversion
- avoid following links

This lowers the risk of UI hitching or startup stalls when cache directories are large.

### Cache Clearing Strategy

Cache clearing will be normalized so each operation:

- checks existence first
- deletes with awaited async calls
- uses a shared helper for repeated patterns

Behavior remains the same from the user's point of view: cache can still be cleared at startup or from the About page.

## 3. Shared Widget Stabilization

### Target

`lib/common/widgets/self_sized_horizontal_list.dart`

### Current Issues

- Height measurement depends on a post-frame `setState` path that is triggered too broadly.
- Cached height does not have a clear invalidation policy when widget configuration changes.

### Proposed Changes

- trigger measurement refresh only when needed
- restore/update lifecycle-based invalidation such as `didUpdateWidget`
- invalidate cached height when inputs that affect layout change
- preserve the current behavior of using the first item as the height reference

This keeps the widget behavior stable while reducing unnecessary rebuild work.

## Error Handling

### Search Suggestions

- Empty or whitespace-only input clears suggestions and skips requests.
- Failure from an outdated request is ignored.
- Failure from the latest request results in a clean empty suggestion state rather than leaving stale results visible.

### Cache Operations

- Utility helpers bubble meaningful exceptions upward.
- The About page continues to own user-facing toast/error messaging.
- No silent-success behavior will be introduced for failed deletions.

## About Page Behavior

`AboutPage` will remain the user-facing consumer of cache utilities.

Changes:

- protect cache-size refresh against overlapping requests
- avoid writing stale async results after the page is disposed or superseded by a newer refresh
- preserve the current clear-cache flow and messages

## Testing and Verification

### Static Verification

- run `dart format` on touched files
- run `flutter analyze`

### Manual Verification

- search page:
  - typing
  - clear input
  - submit
  - UID jump
  - history insert/remove/clear
  - import/export history
  - hot search refresh
  - recommend refresh
- about page:
  - cache size display
  - clear cache
  - re-query cache size after clearing
- pages using `SelfSizedHorizontalList`:
  - first render
  - resize/orientation/window changes

### Optional Unit Tests

If cleanly extractable without widening scope, add tests for:

- stale suggestion response rejection
- pure cache helper behavior such as formatting or aggregation

## Risks

- `SelfSizedHorizontalList` may rely on implicit behavior in a few call sites; any lifecycle cleanup must preserve first-frame layout.
- Cache traversal changes may expose previously hidden file-system exceptions; these should be surfaced clearly rather than masked.
- Search UI refactoring must not accidentally change navigation parameters or search submission behavior.

## Rollback Strategy

Each touched area is isolated enough to revert independently:

- search controller/page files
- cache utility
- about page
- shared list widget

This is intentional because the worktree already contains unrelated changes.

## Expected Outcome

After implementation:

- search input updates should rebuild less UI
- search suggestions should no longer regress under out-of-order responses
- cache size calculation and cache clearing should rely on cleaner, more predictable async IO
- the touched code should have sharper ownership boundaries and lower maintenance cost
