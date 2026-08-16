# App Review Notes — PropNote 1.0.0

Paste-ready notes for the "App Review Information" → "Notes" field in App
Store Connect.

---

```
PropNote is a fully local-first personal property notebook for real
estate agents and anyone who regularly visits properties for sale. There
is no account system and no login — all data (property details, photos,
documents, GPS coordinates) is stored directly on-device in a local SQLite
database. There is no PropNote backend server; nothing syncs to the cloud.

NO DEMO ACCOUNT NEEDED
Since the app has no accounts or sign-in of any kind, there is nothing to
provide credentials for. The app is immediately usable after install —
tap "+" on the Map or List screen to add a property.

FREE / PRO TIERS
- Free tier: up to 10 properties, no time limit. This count includes
  properties currently in Trash (soft-deleted) — only permanently deleting
  a property frees up a slot. This is intentional and disclosed in-app
  (Settings and the paywall).
- PropNote Pro: an auto-renewing annual subscription
  (product ID: propnote_pro_yearly) that removes the 10-property limit.
  If a Pro subscription lapses or is cancelled, all existing data remains
  fully accessible (view/edit/delete/backup) — only creating NEW
  properties is blocked again once the count is at/over 10.
- "Restore Purchases" is available directly on the paywall screen
  (Settings → PropNote Pro → Nâng cấp lên Pro, or when the Free limit is
  reached while adding a property).
- Manage/cancel subscription: PropNote links out to the standard
  App Store subscription management page (Settings → Manage Subscription),
  same as any other app — PropNote does not handle billing directly.

TO TEST THE FREE QUOTA
Add 10 properties via the "+" button (Map or List screen). On the 11th
attempt, the app shows a paywall explaining the limit before allowing the
purchase flow. Deleting a property permanently from Trash (Cài đặt →
Thùng rác → xoá vĩnh viễn) frees up a slot again.

MAPS
PropNote bundles offline map data (PMTiles format) for two regions only:
TP. Hồ Chí Minh and Hà Nội. There is no Google Maps SDK and no Google Maps
API key in this app. Viewing a property located outside these two regions
still works normally (the map shows a neutral gray background with a
"Bản đồ chưa hỗ trợ khu vực này." — "Map not supported for this area yet"
— message, but the property's coordinates are still saved/editable/usable
normally). Tapping "Chỉ đường bằng Google Maps" (Get Directions) opens the
Google Maps app (or the system's default maps app) via a plain external
deep link — this requires Internet and is handled entirely outside
PropNote; no API key or embedded map SDK is involved.

KNOWN MINOR UI ISSUE (non-blocking, already reviewed and accepted for 1.0)
When switching between the TP.HCM/Hà Nội map region buttons, a small
"map not supported here yet" banner can occasionally flash or linger
briefly before clearing on the next touch. The map itself always renders
the correct region correctly, there is no crash and no data loss — this is
a cosmetic timing issue, not a functional defect.

PERMISSIONS REQUESTED
- Location (When In Use): to place a pin at the user's current position
  when adding/editing a property, and to show "you are here" on the map.
  Never collected in the background.
- Camera / Photo Library: to attach photos to a property.
- Microphone / Speech Recognition: optional voice-to-text input for the
  property name/notes fields. Processed by the OS's own speech recognition
  (Apple's on-device/Siri speech services), not by any PropNote server —
  PropNote has no server to send audio to.

No analytics, no advertising SDKs, no third-party tracking are integrated
in this build.
```

## Ghi chú thêm (không cần paste, chỉ để tham khảo nội bộ)

- Nếu Apple hỏi lý do dùng vị trí (Location) trong Purpose String, đối
  chiếu đúng chuỗi hiện có trong `ios/Runner/Info.plist`
  (`NSLocationWhenInUseUsageDescription`) trước khi trả lời khác đi.
- Nếu reviewer yêu cầu video/ảnh minh hoạ subscription flow, có thể quay
  màn hình paywall trực tiếp trên simulator/thiết bị thật — không cần
  chuẩn bị trước trừ khi Apple yêu cầu cụ thể.
