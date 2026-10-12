# 🎓 Attendly — Smart Attendance Tracker

**A modern Flutter application that helps students track attendance, monitor subject-wise performance, and plan how to maintain the required 75% attendance.**

Attendly provides an intuitive dashboard, real-time attendance calculations, attendance history, and a smart calculator to help students make informed decisions about their classes.

## ✨ Features

- 📊 **Smart Dashboard** — View overall attendance, attended classes, total classes, and subjects requiring attention.
- 📚 **Subject Management** — Add subjects with custom names and subject codes.
- ✅ **Quick Attendance Marking** — Record classes as Present or Absent with a single tap.
- 📈 **Visual Progress Tracking** — Monitor subject-wise attendance through animated progress indicators.
- 🧮 **Smart Attendance Calculator** — Calculate how many consecutive classes you need to attend to reach 75% attendance and how many additional classes you can miss while staying above the threshold.
- 🕒 **Attendance History** — Review previously recorded attendance activities.
- 💾 **Local Data Persistence** — Save subject details and attendance records on your device.
- 🌐 **REST API Integration** — Fetch motivational quotes from an external API.
- 📱 **Responsive UI** — Adapt the layout to different screen sizes.
- 🎨 **Modern Interface** — Clean Material 3 design, custom cards, progress indicators, and a consistent color palette.
- 🧪 **Unit Testing** — Test attendance calculations and application logic.

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI development |
| Dart | Application programming |
| Material 3 | Modern interface design |
| Provider | State management |
| `setState` | Local widget state management |
| SharedPreferences | Local data persistence |
| HTTP | REST API requests |
| Flutter Test | Unit testing |

## 📸 UI Preview

Add screenshots of your running application to a `screenshots/` directory in this repository.

Once you add the files, you can display them here:

| Dashboard | Subjects |
|---|---|
| ![Dashboard](screenshots/dashboard.png) | ![Subjects](screenshots/subjects.png) |

| Attendance Calculator | History |
|---|---|
| ![Calculator](screenshots/calculator.png) | ![History](screenshots/history.png) |

*Note: Add the corresponding screenshot files before relying on these image previews.*

## 🚀 Getting Started

### Prerequisites

Install the following tools:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/)
- [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/akshayaregidi07-source/SmartAttendaceTracker.git
```

**2. Navigate to the project directory**

```bash
cd SmartAttendaceTracker
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Run the application**

```bash
flutter run
```

**5. Run the tests**

```bash
flutter test
```

## 📂 Project Structure

```text
SmartAttendaceTracker/
├── lib/
│   └── main.dart
├── test/
│   └── attendance_store_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## 🧮 Attendance Calculation

Attendly uses the following formula:

**Attendance Percentage**

```text
Attendance = (Classes Attended / Total Classes) × 100
```

**Classes Required to Reach the Target**

If the current attendance is below 75%, the app calculates the minimum number of consecutive classes you must attend to reach the target.

**Safe Additional Absences**

If attendance is already at or above 75%, the app estimates the maximum number of additional classes you can miss while maintaining the target, assuming all other classes are attended.

Cancelled classes are excluded from the attendance denominator.

## 🎯 Academic Relevance

This project demonstrates practical implementation of Flutter UI development concepts:

- Dart fundamentals and reusable widgets
- Row, Column, Stack, and responsive layouts
- Navigation between application screens
- Stateful and stateless widgets
- State management with `setState` and Provider
- Forms and input validation
- Custom styling and themes
- REST API integration
- Unit testing and debugging

## 🔮 Future Enhancements

- 🔔 Attendance threshold notifications
- 📅 Calendar-based attendance tracking
- ☁️ Cloud synchronization and account authentication
- 📄 Attendance report export to PDF or CSV
- 📉 Attendance trend charts and analytics
- 🏫 Timetable integration
- ✏️ Edit and delete individual attendance records

## ⚠️ Current Limitations

- The app starts with sample subject and attendance data.
- Data is stored locally on the device and is not synchronized across devices.
- The motivational quote feature depends on an external API and an available internet connection.
- Attendance calculations are estimates based on recorded classes; institutional attendance rules may differ.

## 👩‍💻 Author

**Akshaya Regidi**

B.Tech — Computer Science and Engineering

GitHub: [@akshayaregidi07-source](https://github.com/akshayaregidi07-source)

## 📄 License

This project is developed for educational purposes as part of a Flutter User Interface Design (UID) project.

A formal open-source license can be added if you intend to distribute or reuse the project under specific terms.

---

⭐ **If you find this project useful, consider giving the repository a star!**
