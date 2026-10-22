# App Lock: Biometric + App PIN

> **Deliverable right now:** this plan saved as `APP_LOCK_PLAN.md` in the repo root. Nothing gets implemented until it's approved separately.

## Context

Fusion is a local-only password vault. At the moment, every cold start drops the user on the master-password `LoginScreen`, because `AuthService._loggedIn` lives only in memory. Leaving the app and coming back never re-locks it.

What's wanted:
- After the first master-password login (or signup), the user has to set up an app lock.
- From then on, every time the app opens (cold start **and** every return from the background), the user unlocks with **biometrics** or a **Fusion app PIN**.

The vault isn't encrypted with a key derived from the master password. `VaultStore` keeps plain JSON in OS secure storage (`fusion.vault.v1`), and the master password is only a gate. That means a PIN or biometric gate doesn't weaken any cryptography. It replaces one UI gate with another.

### Decisions made (by user)
| Topic | Choice |
|---|---|
| "Passcode" | A new **Fusion app PIN**, not the phone's screen lock |
| When to lock | **Cold start + every return from background**, with no grace period |
| Opt-in | **Mandatory**: after login, the user can't reach the vault until a PIN is set |
| Fallback | A **"Use master password instead"** link on the lock screen |

### Calls made in this plan (open to change)
- The PIN is a fixed **6 digits**.
- Biometrics are an **optional add-on** to the mandatory PIN. They're offered during setup only if the device supports them, and can be toggled in Settings. The PIN alone meets the "mandatory" requirement, and it works on web and Linux, where biometrics don't.
- **5 wrong PINs** disable the PIN until the user logs in with the master password. The failed-attempt count survives app restarts.
- The lock triggers on the `hide` lifecycle event, not `inactive`. That way the notification shade, Control Center and the biometric sheet itself don't re-lock the app.
- When the app re-locks after a return from the background, the lock screen is **pushed as a route on top of the current navigation stack**. A half-filled form is still there after unlocking.

## Flow

```
Login / Signup ──► no PIN yet? ──► AppLockSetupScreen (mandatory)
                                    1. Create PIN  2. Confirm PIN
                                    3. "Use Face ID / fingerprint?" (only if available)
                                  ──► HomeShell

Cold start (account + PIN) ──► LockScreen(launch)
        biometric auto-prompt │ PIN pad │ "Use master password instead"
        success ──► auth.unlockWithAppLock() ──► HomeShell

App hidden while logged in ──► push LockScreen(resume) on top of the stack (no animation)
        success ──► pop ──► back exactly where the user was
        "Use master password" ──► popUntil first, vault.reset(), auth.logout(),
                                  lock.requestMasterPassword() ──► LoginScreen
```

`AuthGate` decision order (`lib/main.dart`):
1. `!auth.ready` → `_Splash`
2. `auth.loggedIn && !lock.hasPin` → `AppLockSetupScreen`
3. `auth.loggedIn` → `HomeShell`
4. `auth.hasAccount && lock.hasPin && !lock.masterPasswordRequested` → `LockScreen(launch)`
5. `auth.hasAccount` → `LoginScreen`
6. otherwise → `WelcomeScreen`

## Implementation

### Dependency and platform setup
- `pubspec.yaml`: add `local_auth: ^3.0.2`. Version 3.x throws `LocalAuthException` instead of `PlatformException`. **Check the exact `authenticate()` parameter names (biometric-only / sticky) in the 3.0.2 API reference before coding.**
- `ios/Runner/Info.plist`: add `NSFaceIDUsageDescription` ("Unlock your Fusion vault with Face ID").
- Android is mostly ready already:
  - `MainActivity.kt` already extends `FlutterFragmentActivity`.
  - `AndroidManifest.xml` already has `USE_BIOMETRIC`.
  - Check the current local_auth README to see whether `LaunchTheme`/`NormalTheme` in `res/values{,-night}/styles.xml` must be switched to `Theme.AppCompat.*`. They currently use `@android:style/Theme.Light/Black.NoTitleBar`.
- macOS (Touch ID) and Windows (Hello) are supported by local_auth. Web and Linux aren't, so they get the PIN only.
- `tool/setup.sh` and `tool/setup.ps1`: also patch `NSFaceIDUsageDescription` so a regenerated `ios/` keeps it.

### New files
| File | Purpose |
|---|---|
| `lib/services/hashing.dart` | Moves `_hashWorker`, `_newSalt` and `_equals` out of `auth_service.dart` as public `stretchHash`, `newSalt` and `constantTimeEquals`. Both the master password and the PIN use them. |
| `lib/services/biometric_auth.dart` | An abstract `BiometricAuth` with `Future<BiometricKind> available()` (none, face, fingerprint or generic) and `Future<bool> authenticate(String reason)`, plus a `LocalBiometricAuth` implementation backed by `local_auth`. It catches `LocalAuthException` and `MissingPluginException`, and returns `none` on web. The interface lets tests inject a fake, since the project has no mocking library. |
| `lib/services/app_lock_controller.dart` | A `ChangeNotifier` that copies the `ThemeController` pattern: injectable `FlutterSecureStorage` (default `fusionStorage`), an `init()` with a safe fallback, and a key `fusion.applock.v1` holding JSON `{salt, hash, biometric, failed}`. Details below the table. |
| `lib/screens/app_lock_setup_screen.dart` | The mandatory setup, in three steps: create PIN, confirm PIN, then an optional biometric step. Enabling biometrics runs one real prompt to confirm. There's no back or skip button on the PIN steps. The same screen handles a `change` mode used from Settings, which asks for the current PIN first. |
| `lib/screens/lock_screen.dart` | `LockScreen(mode: launch \| resume)`. Details below the table. |
| `lib/widgets/pin_pad.dart` | `PinDots` and `PinPad`: a 3×4 grid with digits, backspace and an optional biometric key. It uses `Pressable` and haptics and has no `TextField`. |
| `lib/widgets/app_lock_guard.dart` | A `StatefulWidget` placed in `MaterialApp.builder`. Details below the table. |

**`AppLockController` API:**
- Read-only state: `hasPin`, `biometricEnabled`, `biometricKind`, `failedAttempts`, `pinLockedOut` (5 or more failures), `masterPasswordRequested`, `authInProgress`.
- Actions: `setPin`, `verifyPin` (hashes in `compute()` and saves the failure count), `setBiometric`, `tryBiometric(reason)`, `requestMasterPassword`, `cancelMasterPassword`.
- `tryBiometric` sets `authInProgress` and clears it about 500 ms after the prompt finishes. Some platforms deliver lifecycle events after the future resolves.
- The constructor takes `AuthService` and listens to it:
  - When `loggedIn` turns true, it clears `failed` and `masterPasswordRequested`.
  - When `hasAccount` turns false (after an erase), it resets its in-memory state. `wipe()` has already run `deleteAll()` on storage.

**`LockScreen`:**
- Violet background with `FusionLogo`, the same look as `_Splash`.
- Shows "Welcome back, {firstName}", the PIN dots and pad, and a biometric button.
- Prompts for biometrics automatically when it appears, if they're enabled.
- A wrong PIN plays `Shake` and shows "Wrong PIN · N tries left".
- After 5 wrong PINs the pad is disabled and the screen shows "Too many attempts. Use your master password."
- In resume mode it's wrapped in `PopScope(canPop: false)`.

**`AppLockGuard`:**
- Uses `AppLifecycleListener(onHide: …)`.
- On hide, if `auth.loggedIn && lock.hasPin && !lock.authInProgress && !_lockShown`, it:
  1. unfocuses the current field;
  2. pushes the resume lock route through `navigatorKey`, as an opaque `PageRouteBuilder` with `transitionDuration: Duration.zero` so the first frame after resume is already the lock;
  3. sets `_lockShown`.
- It clears `_lockShown` when that route pops.

### Changes to existing files
- **`lib/main.dart`**
  - Create `AppLockController(auth: auth)` and `await lock.init()` before `runApp`, next to `theme.init()`.
  - Add it to `MultiProvider`.
  - Give `MaterialApp` a `navigatorKey` and `builder: (c, child) => AppLockGuard(navigatorKey: …, child: child!)`.
  - Update `AuthGate` to the six branches listed above.
- **`lib/services/auth_service.dart`**
  - Use `hashing.dart`.
  - Add `unlockWithAppLock()`, which sets `_loggedIn = true` and notifies listeners.
- **`lib/screens/login_screen.dart`**: when `lock.hasPin && !lock.pinLockedOut`, show an "Unlock with PIN instead" `TextLink` that calls `lock.cancelMasterPassword()`.
- **`lib/screens/settings_screen.dart`**
  - Add an "App lock" card in the same style as the Appearance card.
  - The card has a biometric row with `FusionSwitch` (`components.dart:836`), hidden when biometrics aren't available. Turning it on runs a real prompt first.
  - It also has a "Change PIN" row that pushes `AppLockSetupScreen(mode: change)` through `fusionRoute()`.
  - The "Lock vault" subtitle becomes "Ask for your PIN or {Face ID/fingerprint}". Its behaviour doesn't change, since `logout()` now lands on `LockScreen`.
  - Bump the later `FadeSlideIn` delays.
- **`lib/widgets/icons.dart`**: add `FIcons.fingerprint` and `FIcons.faceId` SVG path strings.

### Reuse (don't rebuild)
- `context.fc` tokens and `FT.*` typography from `lib/theme.dart`.
- `statusBarFor` / `lightStatusBar` and `fusionRoute()` from `lib/theme.dart`.
- `PrimaryButton`, `TextLink`, `FusionSwitch` and `FusionLogo` from `lib/widgets/components.dart`.
- `Shake`, `Pressable`, `FadeSlideIn` and `PopIn` from `lib/widgets/motion.dart`.
- The `fusionStorage` instance from `lib/services/storage.dart`.

## Edge cases
- **Biometric prompt causing a re-lock loop:** the guard skips while `authInProgress` is set or the lock route is already shown.
- **"Open website" and copying to another app:** these re-lock on return, as the "every return" choice implies.
- **Biometrics removed from the device:** `authenticate` fails and the user falls back to the PIN.
- **Lock storage can't be read:** the app treats it as "no PIN". After the next master-password login the user goes through setup again, which overwrites the old record.
- **Erase vault:** `deleteAll()` removes the lock key, and the controller resets through its auth listener.
- **Forgot PIN:** "Use master password", then change the PIN in Settings. A forgotten master password still goes through the existing reset flow.

## Non-goals
- A privacy cover in the app switcher (blur or `FLAG_SECURE`).
- Encrypting the vault with a key protected by biometrics.
- Detecting changes to the enrolled biometrics.
- A grace period.
- Letting the user turn the app lock off.

## Verification
1. Run `dart format --language-version=latest lib test`. Plain `dart format` reformats code that isn't part of the change.
2. Run `flutter analyze` and expect it to be clean.
3. Run `flutter test`, which includes these new tests:
   - `test/app_lock_controller_test.dart`, with `FlutterSecureStorage.setMockInitialValues({})`: set and verify the PIN; the failed count persists across a new controller; lockout at 5; failures clear on an auth login; the biometric flag persists; state resets after a wipe.
   - `test/lock_screen_test.dart`, with a `FakeBiometricAuth`: entering the right PIN unlocks (`auth.loggedIn`); a wrong PIN shows the error; lockout disables the pad; the biometric prompt fires automatically.
   - `test/auth_gate_test.dart`: each of the six branches.
   - Update `test/settings_theme_test.dart` to provide an `AppLockController`.
4. Manual checks on the iOS simulator (Features → Face ID → Enrolled / Matching / Non-matching Face) and an Android emulator (Extended controls → Fingerprint):
   - signing up forces PIN setup;
   - a cold start shows the lock screen;
   - backgrounding and returning shows the lock over the same screen, with form state kept;
   - the Face ID sheet doesn't cause a loop;
   - 5 wrong PINs force the master password;
   - Erase leads back to Welcome.
5. Check that a web or desktop build without biometrics offers the PIN only.

## As built (changes from this plan)

Implemented on `feature/v2-UI`. These points differ from the plan above:

- **Windows:** biometrics are not offered. Windows Hello can't be limited to biometrics (it always allows the Windows PIN), and the fallback here is the Fusion PIN. Windows, web and Linux get the PIN only.
- **No `authInProgress`:** the guard locks on every `hide`. The biometric sheet only makes the app inactive, so it never triggers a lock, and a real trip home during a prompt now locks as it should.
- **The lock can't be popped by accident:** the lock route completes with `true` only when the user unlocks. If anything else pops it (a screen closing itself after a save), the guard pushes it straight back. Screens that close themselves after an `await` use `closeRoute()` in `lib/theme.dart`, which removes only their own route.
- **Forgot PIN:** after a master-password login (`AuthService.passwordVerified`), Change PIN skips the "current PIN" step.
- **"Lock vault":** it doesn't fire the biometric prompt by itself (`skipNextAutoPrompt()`). The Face ID / fingerprint key on the pad still works.
- **Lockout:** biometrics are refused while the PIN is locked out, so only the master password gets back in.
- **Setup order:** during the mandatory setup the PIN is saved only after the biometric choice, because saving it moves the app straight on to the vault.
- **Settings layout:** the App lock section is a card of rows (biometric switch, Change PIN), not a card with a header.
- **Android:** `LaunchTheme` and `NormalTheme` now use `Theme.AppCompat.Light.NoActionBar` and `Theme.AppCompat.NoActionBar`. `tool/setup.sh` and `tool/setup.ps1` also patch `USE_BIOMETRIC`, `FlutterFragmentActivity` and the AppCompat themes.

**Known gaps (not fixed):**
- **Forgot password:** the existing reset flow shows its code on the same device. Anyone holding the phone can reset the master password, which gets around the PIN lockout.
- **Smaller issues** found in review:
  - a faint ~200 ms glimpse of the screen behind the lock when choosing "Use master password instead";
  - an unlock that finishes while the app is hidden isn't locked again;
  - a newly enrolled Face ID or fingerprint is noticed only after a restart;
  - the PIN pad doesn't take input from a hardware keyboard;
  - weak PINs such as 000000 are accepted.
