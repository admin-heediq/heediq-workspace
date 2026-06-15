# Loading & Feedback — The System Is Always Responsive

Principle: **the user is never left wondering what's happening.** Every wait is visible, every action
gets an acknowledgment, every outcome (success/error) is communicated. Heediq runs long jobs
(transcription, diarization, summarization), so this is core to the product feel, not polish.

All feedback is delivered through **kit components** (Spinner, ProgressBar, SkeletonBlock, Toast,
EmptyState, ErrorState — see `03-ui-kit.md`), never one-off markup.

---

## 1. No silent waits
Any async operation that can exceed ~300ms must show visible feedback. Nothing should ever appear
frozen. If you're awaiting something, the UI says so.

## 2. Page-level loading → skeletons, not blank screens
When a whole page/route is loading, show a **skeleton that mirrors the eventual layout** (lists,
cards, the transcript pane), not a generic centered spinner. Skeletons preserve layout, cut perceived
wait, and prevent layout shift when real content arrives. A top-of-page progress bar may accompany
route transitions.

## 3. Section / partial loading
For partial updates, load only the affected region (a card, a panel) with its own skeleton or inline
spinner — never block the whole screen for a local fetch.

## 4. Button & action loading state
On any action that triggers async work, the trigger control enters its **loading state**: spinner +
disabled + **width preserved** (no layout jump), with label like "Saving…". The control is disabled
while pending so the action can't be **double-submitted**. The three-state Listen button (idle →
recording → processing) is the reference pattern.

## 5. Long-running jobs → determinate progress with stages
Transcription/summarization are long. Show **real progress**, not an endless indeterminate spinner:
a stage indicator (`queued → transcribing → diarizing → summarizing → ready`) and a percentage/bar
where the backend can report it. Surface the current stage in plain language. Reflect the actual
pipeline state from SQS/Fargate, polled or streamed — don't fake it.

## 6. Optimistic UI where safe
For low-risk mutations (rename, toggle, reorder), update the UI immediately and **roll back on error**
with a toast. Don't use optimistic UI for operations where a wrong-then-corrected state would mislead
(payments, destructive actions) — those wait for the server.

## 7. Outcome feedback — success & error toasts
Every completed operation gives feedback:
- **Success** — a brief, non-blocking toast/inline confirmation ("Recording saved", "Pushed to
  Jira").
- **Error** — a clear, **actionable** toast/inline message: what failed, what to do, and a **Retry**
  where applicable. Never swallow an error into a blank screen or a silent no-op.

## 8. Designed empty states (distinct from loading)
Empty ≠ loading. When there's genuinely no data, show a designed `EmptyState` with a short
explanation and a primary action ("No recordings yet — Start your first recording"), not a bare blank
region.

## 9. Designed error states for every data fetch
Every data-loading surface has three branches: **loading (skeleton) · success (content) · error
(ErrorState with Retry)**. A failed fetch must never leave the user staring at an empty container.

## 10. Perceived-performance details
- **Instant click feedback** (<100ms): the control reacts immediately (press state) even before the
  request resolves.
- **Spinner delay threshold**: for very fast operations, delay showing a spinner ~150–200ms so it
  doesn't flash; once shown, keep it up a **minimum** time (~400ms) to avoid flicker.
- **Stale-while-revalidate**: show cached data immediately with a subtle "refreshing" indicator while
  fresh data loads, rather than a full skeleton on every revisit.
- **No layout shift**: reserve space for content that's loading (skeletons/placeholders sized to the
  real thing).

## 11. Global async conventions
- Use a server-state library (e.g. TanStack Query) so loading/error/refetch states are consistent and
  cached app-wide rather than hand-rolled per screen.
- Centralize toast handling (one Toaster) and error normalization so every failure renders the same
  way.
- For very long jobs, the user can navigate away and be notified on completion (toast / badge);
  progress survives navigation.

---

## Definition of done for any data/async UI
- [ ] Loading state visible (skeleton for pages/sections, button-loading for actions)
- [ ] Long jobs show staged, determinate progress reflecting real backend state
- [ ] Success feedback present; error feedback present, actionable, with Retry where applicable
- [ ] Empty state and error state both designed (no blank screens)
- [ ] No double-submit; no layout shift; spinner delay/min-display applied
- [ ] All feedback rendered via kit components, not one-off markup
