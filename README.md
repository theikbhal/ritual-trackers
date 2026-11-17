# 🔁 Ritual Trackers (macOS, Swift)

Three separate Mac apps for repeatable habits ("rituals"):

| App | Cadence | Reminder |
|---|---|---|
| **Weekly Rituals** | every week (Sun–Sat) | pick weekday + time |
| **Monthly Rituals** | every month | pick day of month + time |
| **Yearly Rituals** | every year | pick month, day + time |

Each app has its own data, streaks and notifications.

## Features
- Add any number of rituals (each starts with one example you can edit or delete)
- Checkbox for the current period, plus history to check/uncheck past periods
- Streak, best streak, total done
- **Benefit** for each ritual (why it matters), plus "Ask AI about the benefits"
- General notes per ritual, plus a note on every ticked period
- Per-ritual repeating notifications
- In-app help; data stays on your Mac

## Examples
- Weekly: Eat papaya 🥭 (≈₹40-50/kg, vitamin C, digestion, iron absorption, kids love it)
- Monthly: Review family budget 💰
- Yearly: Annual health check-up 🩺

## Install
Requires macOS 13+ and Xcode or Command Line Tools (`xcode-select --install`).
```bash
./build.sh            # all three
./build.sh weekly     # just one
```
Apps go to `/Applications` and shortcuts to your Desktop.

## Publish to GitHub (gh installed)
```bash
gh auth login        # once
./publish.sh         # creates the repo "ritual-trackers" and pushes
```

## Layout
`Sources/RitualKit` is the shared engine. `Sources/WeeklyRituals`, `MonthlyRituals` and `YearlyRituals` are tiny app entry points.
- App icons live in Icons/ (regenerate with: python3 tools/make_icons.py)
