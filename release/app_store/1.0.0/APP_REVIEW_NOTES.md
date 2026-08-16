# App Review Notes — PropNote 1.0.0

Paste-ready notes for the "App Review Information" → "Notes" field in App
Store Connect.

**Important:** the pasteable block below intentionally does NOT mention
any internal known cosmetic issues (e.g. the map region-switch banner
timing quirk) — those are tracked internally only and are not relevant to
reviewers evaluating core functionality. Do not add them back in when
copying.

---

## FINAL PASTE BLOCK

```
PropNote is a fully local-first personal property notebook for real
estate agents and anyone who regularly visits properties for sale. There
is no account system and no login — all data (property details, photos,
documents, GPS coordinates) is stored directly on-device in a local SQLite
database. There is no PropNote backend server; nothing syncs to the cloud.

NO DEMO ACCOUNT NEEDED
The app has no accounts or sign-in of any kind, so there is nothing to
provide credentials for. It is immediately usable after install — tap "+"
on the Map or List screen to add a property.

FREE / PRO TIERS
- Free tier: up to 10 properties, no time limit. This count includes
  properties currently in Trash (soft-deleted) — only permanently deleting
  a property frees up a slot. This is disclosed in-app (Settings and the
  paywall).
- PropNote Pro: an auto-renewing annual subscription
  (product ID: propnote_pro_yearly) that removes the 10-property limit.
  If Pro lapses or is cancelled, all existing data remains fully
  accessible (view/edit/delete/backup) — only creating NEW properties is
  blocked again once the count is at/over 10.
- "Restore Purchases" is available directly on the paywall screen.
- Manage/cancel subscription: PropNote links out to the standard App
  Store subscription management page — PropNote does not handle billing
  directly.

TO TEST THE FREE QUOTA
Add 10 properties via the "+" button (Map or List screen). On the 11th
attempt, a paywall explains the limit before any purchase flow starts.
Permanently deleting a property from Trash frees a slot again.

MAPS
PropNote bundles offline map data (PMTiles format) for two regions only:
TP. Hồ Chí Minh and Hà Nội. There is no Google Maps SDK and no Google Maps
API key in this app. A property located outside these two regions still
saves/loads normally; the map background for that view simply shows a
neutral "not supported yet" state. Tapping "Get Directions" opens the
device's Google Maps app (or default maps app) via a plain external deep
link — this requires Internet and is handled entirely outside PropNote.

PERMISSIONS REQUESTED
- Location (When In Use): to place a pin at the user's current position
  and show "you are here" on the map. Never used in the background.
- Camera / Photo Library: to attach photos to a property.
- Microphone / Speech Recognition: optional voice-to-text input for the
  property name/notes fields, processed by the OS's own speech
  recognition — PropNote has no server to send audio to.

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
- Known internal-only issue (KHÔNG paste cho Apple): khi chuyển nhanh
  giữa 2 nút khu vực TP.HCM/Hà Nội trên Map Screen, banner "chưa hỗ trợ
  khu vực này" đôi khi flash/lingers ngắn trước khi tự hết ở lần chạm kế
  tiếp — cosmetic, không crash, không mất dữ liệu, đã được user chấp
  nhận là non-blocking cho bản 1.0. Chỉ ghi lại đây để nội bộ theo dõi,
  không đưa vào Review Notes gửi Apple.
