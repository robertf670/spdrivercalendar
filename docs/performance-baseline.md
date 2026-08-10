# Performance Baseline

> **App version:** 3.2.9  
> **Status:** Phase 0 Android emulator and local profile-web baseline captured; physical-device and deployed-domain comparisons are optional follow-up measurements  
> **Purpose:** Capture repeatable evidence before startup or calendar architecture changes.

## Rules

- Measure the current code before changing startup initialization or calendar state ownership.
- Record at least three runs and use the median. Note unusually slow runs separately.
- Use realistic calendar data. Record the approximate number of events and visible year.
- Close unrelated applications and browser tabs where practical.
- Do not compare debug-mode timings with profile or deployed release timings.
- Keep screenshots or exported performance traces with the date and app version.

## Android environment

Complete this before recording results:

- Device or emulator: Android `flutter_emulator` AVD (`sdk gphone64 x86_64`)
- Android version: Android 15 / API 35
- Physical device: no
- Build command: `flutter run --profile`
- Renderer: software-rendered emulator host; app uses Impeller OpenGLES
- Connection: host network
- Existing user data or fresh install: fresh install, onboarding completed
- Approximate event count: 0
- Measurement date: 23 July 2026

## Android measurement checklist

1. Start the app in profile mode:

   ```powershell
   flutter run --profile
   ```

2. Open Flutter DevTools from the URL printed by Flutter.
3. In DevTools Performance, enable frame rendering information.
4. Capture three cold starts:
   - Fully stop the app.
   - Start it again.
   - Measure from launch until the calendar is visible and responds to a day tap.
5. Capture month navigation:
   - Start recording.
   - Move forward six months and back six months at a normal pace.
   - Record dropped/janky frames and the slowest frame.
6. Capture day selection:
   - Tap ten dates containing a mixture of no events, one event, and multiple events.
   - Record the time from input to the selected-day panel updating.
7. Capture event saving:
   - Add or edit five representative events.
   - Record the time from confirming the action until the calendar reflects the saved event.
8. Capture memory:
   - Record memory after the calendar settles.
   - Navigate months and open/close day details for ten minutes.
   - Record final memory and whether it continues rising after returning to idle.

## Android results

| Metric | Run 1 | Run 2 | Run 3 | Median | Target |
|---|---:|---:|---:|---:|---:|
| Cold activity launch | 2.292s | 2.022s | 2.077s | 2.077s | < 2s |
| Month navigation janky frames | Not available | Not available | Not available | Not available | 0 |
| Slowest month-navigation frame | Pending | Pending | Pending | Pending | < 16.7ms |
| Day-tap response | Pending | Pending | Pending | Pending | < 100ms |
| Event-save perceived response | Pending | Pending | Pending | Pending | < 200ms |
| Memory at idle | Pending | Pending | Pending | Pending | Record baseline |
| Memory after representative navigation | 188.4 MiB PSS | — | — | — | Stable after idle |

Android notes:

- `am start -W` supplied repeatable activity-launch timings. These end at Android activity readiness and may not exactly equal the first interactive calendar frame.
- The median is 77ms above the 2-second target, but the software-rendered emulator is not representative of a physical device.
- `dumpsys gfxinfo` did not capture Flutter/Impeller surface frames, so it cannot provide a trustworthy jank count for this run.
- Month navigation, date selection, onboarding, and calendar rendering were exercised successfully in the profile build.
- Firebase Installations returned repeated HTTP 404 responses during startup; investigate configuration separately because retries may affect startup/network behaviour.

## Deployed web environment

Complete this before recording results:

- Deployment URL: pending; local profile server used for this first baseline
- Browser and version: Chrome 148 via Cursor browser
- Operating system: Windows 11 Pro
- Device: Windows host
- Connection: localhost
- Existing user data or fresh browser profile: fresh local browser state, then warm-cache reloads
- Approximate event count: 0
- Deployment/app version: 3.2.9 profile build
- Measurement date: 23 July 2026

## Deployed web measurement checklist

1. Open the deployed domain in a Chromium-based browser.
2. Open Developer Tools and select the Performance panel.
3. For cold-start tests:
   - Enable **Disable cache** while Developer Tools is open.
   - Use a private window or clear only this site’s storage when measuring first-use behaviour.
   - Start recording, hard-refresh the page, and stop after the calendar responds to a day tap.
4. Repeat the cold-start capture three times, clearly distinguishing first-use and warm-cache results.
5. Record month navigation, day selection, and event saving using the same interactions as Android.
6. Review the Main thread, long tasks, frame rate, layout/paint work, and network waterfall.
7. Record memory before and after ten minutes of representative calendar use if the browser exposes a stable memory reading.
8. Save the browser performance trace so later phases can compare the same workflow.

## Deployed web results

| Metric | Run 1 | Run 2 | Run 3 | Median | Target |
|---|---:|---:|---:|---:|---:|
| First contentful paint, first local load | 1.176s | — | — | 1.176s | Record baseline |
| Warm-cache first contentful paint | 0.888s | 0.708s | 0.620s | 0.708s | < 2s |
| Month-navigation long tasks | Pending | Pending | Pending | Pending | 0 over 50ms |
| Day-tap response | Pending | Pending | Pending | Pending | < 100ms |
| Event-save perceived response | Pending | Pending | Pending | Pending | < 200ms |
| Transferred resources on warm load | Pending | Pending | Pending | Pending | Record baseline |
| JS heap after calendar interaction | 143.6 MiB used | — | — | — | Record baseline |

Web notes:

- Local profile-mode results are not a substitute for the deployed-domain network baseline.
- The calendar was navigated repeatedly in both directions without a visible full-screen flash.
- A CPU profile was captured while exercising month navigation.
- Accessibility semantics used for automation materially change DOM node and heap counts, so memory figures should be treated as diagnostic rather than representative of a normal session.
- Bills and Payscale were visually checked at an effective 320px viewport with no horizontal overflow.
- Admin access and Settings fitted at 320px. `UpdateDialog` and `PollDialog` were verified separately with 320px widget tests because they are behind the Admin password.

## Observations

Record:

- The slowest user-visible action: Android cold activity launch (median 2.077s on emulator).
- Whether a full-screen flash occurs on day selection: not observed during automated date selection.
- Whether month navigation visibly stutters: not observed; frame-timeline evidence remains pending.
- Whether startup time is dominated by loading, rendering, or network work: requires a physical-device trace; Firebase retry errors were visible on Android.
- Whether Android and web differ materially: local web reaches first contentful paint faster than the Android emulator reaches activity readiness, but the metrics have different endpoints.
- Any errors or warnings during measurement: Firebase Installations 404 retries on Android; Android `gfxinfo` cannot measure the Flutter Impeller surface.

## Phase 1 comparison

Repeat this exact workflow after each material startup or calendar-state change. Record results in a new dated subsection rather than overwriting the baseline.

No performance improvement is considered verified until the same environment and workflow show a repeatable improvement without a functional regression.
