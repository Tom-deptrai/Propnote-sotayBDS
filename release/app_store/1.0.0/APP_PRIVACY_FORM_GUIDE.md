# App Privacy Form Guide — App Store Connect

Chuẩn bị sẵn câu trả lời cho từng nhóm câu hỏi trong **App Privacy**
(App Store Connect → App → App Privacy). Nguồn sự thật:
`RELEASE_PRIVACY_NOTES.md` ở gốc repo.

**Quy tắc chung của file này:** với bất kỳ câu hỏi nào mà cách diễn giải
phụ thuộc vào wording CỤ THỂ của form (có thể đổi theo thời gian), ghi rõ
`VERIFY IN CURRENT APP STORE CONNECT FORM` thay vì tự đoán — không suy
diễn hộ Apple.

---

## Câu hỏi mở đầu: "Does your app collect any data?"

PropNote **thu thập một số dữ liệu**, nhưng gần như toàn bộ **không rời
khỏi thiết bị** (khác với "collect" theo nghĩa gửi lên server). Cách Apple
muốn bạn khai dữ liệu chỉ xử lý on-device có thể đã thay đổi theo phiên
bản form — `VERIFY IN CURRENT APP STORE CONNECT FORM` trước khi chọn
Yes/No ở câu này.

## Phân loại từng loại dữ liệu (nếu form yêu cầu khai chi tiết)

| Loại dữ liệu (theo nhóm chuẩn của Apple) | Có trong app? | Ghi chú |
|---|---|---|
| **Location** (Precise/Coarse) | Có sử dụng, nhưng chỉ on-device | Dùng GPS để đặt ghim + hiển thị BĐS gần bạn. Không có request mạng nào gửi toạ độ ra ngoài (bản đồ nền local). `VERIFY IN CURRENT APP STORE CONNECT FORM` cho câu hỏi "linked to identity"/"used for tracking" — câu trả lời đúng là **Not linked, Not used for tracking**, nhưng đối chiếu đúng wording hiện hành. |
| **Photos or Videos** | Có sử dụng, chỉ on-device | Ảnh BĐS lưu trong bộ nhớ app, không upload. |
| **User Content — Other User Content (documents)** | Có sử dụng, chỉ on-device | Tài liệu đính kèm BĐS, lưu local. |
| **Contact Info** | KHÔNG khai là "collected từ chính người dùng app" | Trường "liên hệ BĐS" là dữ liệu người dùng tự nhập cho mục đích ghi chú riêng (thông tin của người khác họ muốn nhớ), không phải PropNote thu thập thông tin liên hệ của người dùng app. `VERIFY IN CURRENT APP STORE CONNECT FORM` nếu Apple coi đây là 1 loại cần khai riêng dù không rời thiết bị. |
| **Purchases** | Có — do Apple/StoreKit xử lý | Giao dịch `propnote_pro_yearly`. Apple thường tự nhận diện dữ liệu IAP nó xử lý trực tiếp — đối chiếu wording hiện hành. |
| **Identifiers** (User ID, Device ID) | KHÔNG | App không có account/User ID nào. |
| **Usage Data** (product interaction, ads data) | KHÔNG | Không có analytics SDK. |
| **Diagnostics** (crash data, performance data) | KHÔNG (tại 1.0) | Không tích hợp crash-reporting bên thứ ba. Nếu Apple tự thu thập crash log ở tầng OS (không qua code PropNote), đó là quy trình riêng của Apple, không phải PropNote "collect". |
| **Audio Data** | KHÔNG lưu | Microphone chỉ dùng tức thời cho speech-to-text (xử lý bởi OS), PropNote không lưu file âm thanh. |
| **Search History / Browsing History** | KHÔNG | Tìm kiếm BĐS trong app chỉ lọc dữ liệu local, không gửi đi đâu, không lưu lịch sử tìm kiếm riêng. |
| **Financial Info** | KHÔNG | PropNote không thấy/lưu thông tin thanh toán — Apple xử lý trực tiếp. |
| **Health & Fitness** | KHÔNG | Không áp dụng. |

## Tracking

```
"Do you or your third-party partners use data collected from this app to
track users across apps and websites owned by other companies?"
→ NO
```

Không có SDK quảng cáo/tracking bên thứ ba nào trong app.

## Data Linked to You / Not Linked to You

Vì không có tài khoản/User ID, hầu hết dữ liệu (Location, Photos,
Documents) nên khai **Not Linked to You** — nhưng đây là câu hỏi có thể
diễn giải khác tuỳ version form, `VERIFY IN CURRENT APP STORE CONNECT
FORM` trước khi chốt.

## Purpose (nếu form hỏi mục đích dùng data)

Với Location/Photos/Documents: chọn **App Functionality** (đúng thực tế —
dữ liệu chỉ phục vụ chức năng cốt lõi của app, không phục vụ quảng cáo,
analytics, hay mục đích khác).

## Checklist tổng kết trước khi submit form

- [ ] Location: khai đúng theo nhóm (A) local-only, `VERIFY` wording hiện hành.
- [ ] Photos/Documents: khai local-only, không "collected" theo nghĩa server.
- [ ] Purchases: khai theo hướng dẫn Apple cho IAP tự động nhận diện.
- [ ] Tracking = No.
- [ ] Advertising Data = None.
- [ ] Analytics/Diagnostics từ SDK bên thứ ba = None.
- [ ] Account/User ID = None (app không có account).
- [ ] Đối chiếu lại toàn bộ với `RELEASE_PRIVACY_NOTES.md` nếu có thay đổi
      code liên quan tới dữ liệu trước khi submit version sau này.
