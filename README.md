# Breathin' — Flutter Implementation

Functional prototype for the AMI Final Project.  
**Francisco de Sousa, A50795 — Turma 2N, 2025/2026**

---

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Create the assets directory (needed for pubspec)
mkdir -p assets/sounds

# 3. Run on a physical device (sensors don't work on emulator)
flutter run
```

> **Important:** Always test on a real device. The gyroscope and microphone
> do not function correctly on emulators.

---

## Project Structure

```
lib/
├── main.dart                    # Entry point, theme, orientation lock
├── theme/
│   └── app_theme.dart           # Colors, typography, button styles
├── models/
│   └── session_data.dart        # Session data model + FeedbackMode enum
├── services/
│   ├── feedback_manager.dart    # 4-7-8 breathing timer + haptic/visual output
│   ├── breathing_detector.dart  # Gyroscope-based chest movement detection
│   └── noise_monitor.dart       # Microphone noise sampling
├── utils/
│   └── interaction_logger.dart  # Quantitative logging for usability tests
└── screens/
    ├── home_screen.dart          # START SESSION + settings access
    ├── countdown_screen.dart     # 3s countdown + noise measurement
    ├── active_session_screen.dart# Animated circle + END SESSION
    ├── stats_screen.dart         # Post-session summary
    └── settings_screen.dart      # Preferences + log export
```

---

## Android Permissions Required

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

## iOS Permissions Required

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Breathin' uses the microphone to measure ambient noise and choose the best feedback mode for your environment.</string>
```

---

## Key Design Decisions (Changes from Proj1 → Proj2 → Final)

| Decision | Reason |
|---|---|
| Pre-session screen removed | P1 usability: added cognitive load during panic. Replaced by 3s countdown. |
| Timer removed from session screen | P2 decision: visible countdowns increase anxiety. |
| Pause/stop controls removed | P1 P1: phone is against chest, eyes closed — controls unreachable. |
| "Keep Going" removed from stats | P2: user ended voluntarily → they've recovered. |
| "MAIN MENU" now has home icon | P2 P3 feedback: improves affordance. |
| Save confirmation snackbar added | P2 P3 feedback: confirm settings were applied. |
| Session ends on user decision | Autonomy: recovery from panic is personal and variable. |

---

## Sensors Used

| Sensor | Purpose | Input Type |
|---|---|---|
| Microphone | Ambient noise → auto-select haptic vs visual mode | Environmental |
| Gyroscope | Chest movement detection during session | Body motion |
| Touch | Session start, settings, end session | Direct interaction |

---

## Feedback Modalities

| Modality | When | What |
|---|---|---|
| Visual (animated circle) | Always | Expands on inhale, contracts on exhale |
| Text | Always | Phase label ("Breathe in slowly...") |
| Haptic — heavy impact | Inhale phase | 1 long vibration |
| Haptic — medium impact | Exhale phase | 1 medium vibration |
| Haptic — 3×3 light | Breathing too fast | 3 short × 3 repetitions |

---

## Interaction Logging (Usability Tests)

All sessions are automatically logged to SharedPreferences.  
To export data during testing: **Settings → Export interaction log**.

Logged per session:
- Start/end timestamps
- Session duration (seconds)
- Breathing cycles completed
- Feedback mode (visual / haptic)
- Initial noise level (dB)
- Screen dwell times

To clear between participants: **Settings → Clear interaction log**.

---

## Breathing Pattern: 4-7-8

| Phase | Duration |
|---|---|
| Inhale | 4 seconds |
| Hold | 7 seconds |
| Exhale | 8 seconds |
| **Full cycle** | **19 seconds** |

---

## Dependencies

| Package | Purpose |
|---|---|
| `sensors_plus` | Gyroscope access |
| `noise_meter` | Microphone noise measurement |
| `permission_handler` | Runtime mic permission |
| `flutter_vibrate` | Rich vibration patterns |
| `shared_preferences` | Settings + log persistence |
| `intl` | Date formatting |
