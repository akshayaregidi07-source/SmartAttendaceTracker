# Smart Attendance Tracker

A polished Flutter UID project demonstrating:
- Flutter widgets and custom layouts
- Responsive UI with `LayoutBuilder` / `MediaQuery`
- Navigation between Dashboard, Subjects, History, Calculator, and Settings
- Stateful and stateless widgets
- `setState` and Provider (`ChangeNotifier`)
- Material 3 theme and reusable UI components
- Validated forms
- Fade/slide-style UI transitions and animated progress indicators
- REST API example (optional motivational quote endpoint)
- Unit tests for attendance calculations

## Run the app

1. Install Flutter and confirm `flutter doctor` completes.
2. Extract this ZIP.
3. Open the `smart_attendance_tracker` folder in VS Code or Android Studio.
4. In the terminal, run:

```bash
flutter pub get
flutter run
```

## Notes
- Sample subjects are included so the dashboard looks populated on first launch.
- Attendance records are saved locally with SharedPreferences.
- The REST API example is optional and uses `https://zenquotes.io/api/random`; some networks may block this endpoint. The app remains usable if it fails.
- For a real institutional deployment, attendance records should be backed up and protected with authentication.
