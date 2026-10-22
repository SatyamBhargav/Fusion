# Fusion — password manager (Flutter)

A complete, working Flutter build of the Fusion design: violet + lime, Bricolage Grotesque / DM Sans / DM Mono, and the same screens, spacing and colours as the canvas.

## Run it

Requires Flutter 3.24 or newer (stable).

```bash
cd fusion
./tool/setup.sh        # macOS / Linux  (Windows: ./tool/setup.ps1)
flutter run
```

`setup.sh` runs `flutter create .` to generate the `android/` and `ios/` folders (your `lib/` code is left untouched), adds the Internet permission (Google Fonts) and the https query (Open website) to the Android manifest, sets the app name to “Fusion”, and runs `flutter pub get`.

## What works

| Area | Behaviour |
|---|---|
| **Sign up** | Name, email, master password (live strength meter), confirm (animated match tick), terms checkbox. |
| **Log in** | Validates against the stored hash; wrong password shakes the form. Vault re-locks on every launch. |
| **Forgot / reset** | Email check → 6-digit code (valid 10 min) arrives as an in-app notification banner → OTP boxes + new password. Resend unlocks after a 60 s countdown. |
| **Vault** | Search, filter chips (All / Favourites / Passwords / Social), favourites carousel, star toggle on every row, empty states. |
| **Save a login** | Segmented switch between **Password** (username, password, Generate, strength) and **Social sign-in** (Google, Apple, Facebook, X, GitHub, Microsoft + account email). |
| **Detail** | Reveal / copy password (clipboard auto-clears after 45 s), copy username, open website, favourite, edit, delete (confirm sheet). |
| **Edit** | Same form, prefilled; can switch a login between password and social. |
| **Generator** | Length 8–40, upper / lower / numbers / symbols, regenerate, copy, “Save this password”; also opens as a picker from the form’s Generate button. |
| **Settings** | Lock vault, erase everything. |

## Animations

- Staggered fade-and-rise on every screen; springy pop-in for the decorative shapes.
- Welcome: floating, bobbing cards; the “Generated” card re-scrambles a new password every few seconds.
- Generator: passwords *decode* from random glyphs, the regenerate icon spins, Copy flips to Copied, strength bars fill one by one.
- Page transitions slide and fade; the site tile flies from the list into the detail header (Hero).
- Focus rings glow in, fields shake on errors, stars pop, switches and the segmented control slide with a little overshoot, and the bottom-nav pill stretches to show its label.
- Reset code slides down as a notification; delete sheet icon bounces in.

## Security model (local-only)

- Everything lives in `flutter_secure_storage` (Android Keystore-backed AES-GCM / iOS Keychain). Nothing is uploaded.
- The master password is never stored: only a salted SHA-256 hash, stretched 20,000 rounds, computed on a background isolate.
- **Reset codes are shown on the device** because there is no mail server. That shows how the flow works, but anyone holding the unlocked phone could reset the password. Before shipping, send the code by email from a backend (or drop the reset flow, as most zero-knowledge managers do).
- The vault data is protected by the OS keystore, not encrypted with the master password itself. For production, derive a key from the master password (Argon2id/PBKDF2) and encrypt the vault with it.

## Project layout

```
lib/
  main.dart                 app + AuthGate (welcome ↔ login ↔ vault)
  theme.dart                colour tokens, type styles, page transition
  services/                 auth, vault store, generator, model
  widgets/                  icons, motion, inputs/buttons, toasts & sheets
  screens/                  one file per screen
test/widget_test.dart       generator, strength & model tests
tool/setup.sh / setup.ps1   one-time platform setup
```

## Notes

- Social providers are shown as letter tiles. Replace them with the official brand icons, following each brand’s guidelines.
- Fonts download from Google Fonts on first launch. To work fully offline, bundle the `.ttf` files and set `GoogleFonts.config.allowRuntimeFetching = false`.
