# App Privacy Form Guide — App Store Connect

Chuẩn bị sẵn câu trả lời cho từng nhóm câu hỏi trong **App Privacy**
(App Store Connect → App → App Privacy). Nguồn sự thật:
`RELEASE_PRIVACY_NOTES.md` ở gốc repo.

**Quy tắc chung của file này:** với bất kỳ câu hỏi nào mà cách diễn giải
phụ thuộc vào wording CỤ THỂ của form (có thể đổi theo thời gian), ghi rõ
`VERIFY IN CURRENT APP STORE CONNECT FORM` thay vì tự đoán — không suy
diễn hộ Apple.

---

## Phân biệt quan trọng trước khi điền form: "used on device" khác "collected"

Apple định nghĩa "collect" trong App Privacy là dữ liệu được **truyền đi
khỏi thiết bị** (transmitted off the device) — không phải mọi dữ liệu app
đọc/ghi trên máy. PropNote đọc Location/Photos/Documents để hoạt động,
nhưng không có request mạng nào gửi các dữ liệu này ra ngoài (xem
`RELEASE_PRIVACY_NOTES.md` và code — không có backend, không có SDK
transmit data). Theo đúng định nghĩa này, dữ liệu chỉ xử lý on-device
**không tự động trở thành "collected"** theo nghĩa Apple dùng trong form.

Tuy vậy cách đúng để khai vẫn phụ thuộc wording CỤ THỂ của form tại thời
điểm bạn submit (Apple có thể diễn giải hoặc đổi UI câu hỏi theo thời
gian) — mọi câu trả lời dưới đây chỉ là **đề xuất dựa trên implementation
thật của PropNote 1.0**, không phải khẳng định tuyệt đối. Luôn đối chiếu
`VERIFY IN CURRENT APP STORE CONNECT FORM` trước khi chốt.

## Câu hỏi mở đầu: "Does your app collect any data?"

`VERIFY IN CURRENT APP STORE CONNECT FORM` trước khi chọn Yes/No — dựa
trên phân biệt ở trên, phần lớn dữ liệu PropNote đọc/ghi là on-device-only
nên có thể không tính là "collected", nhưng dữ liệu giao dịch mua (do
Apple xử lý) và khả năng nhận dạng giọng nói xử lý ngoài thiết bị (tuỳ
phiên bản iOS) là các trường hợp cần đối chiếu kỹ trước khi chọn.

## Phân loại từng loại dữ liệu (nếu form yêu cầu khai chi tiết)

| Loại dữ liệu (theo nhóm chuẩn của Apple) | Có trong app? | Ghi chú |
|---|---|---|
| **Location** (Precise/Coarse) | Dùng on-device để đặt ghim + hiển thị BĐS gần bạn | Không có request mạng nào gửi toạ độ ra ngoài (bản đồ nền local). Không tự nhận là "collected" nếu form định nghĩa collect = transmit off-device — nhưng `VERIFY IN CURRENT APP STORE CONNECT FORM` cho đúng wording hiện hành trước khi chọn Yes/No và "linked to identity"/"used for tracking" (PropNote không có identity/account để liên kết, và không dùng cho tracking). |
| **Photos or Videos** | Dùng on-device | Ảnh BĐS lưu trong bộ nhớ app, không upload. `VERIFY` tương tự Location. |
| **User Content — Other User Content (documents)** | Dùng on-device | Tài liệu đính kèm BĐS, lưu local. `VERIFY` tương tự Location. |
| **Contact Info** | KHÔNG khai là "collected từ chính người dùng app" | Trường "liên hệ BĐS" là dữ liệu người dùng tự nhập cho mục đích ghi chú riêng (thông tin của người khác họ muốn nhớ), không phải PropNote thu thập thông tin liên hệ của người dùng app. `VERIFY IN CURRENT APP STORE CONNECT FORM` nếu Apple coi đây là 1 loại cần khai riêng dù không rời thiết bị. |
| **Purchases** | Có — do Apple/StoreKit xử lý | Giao dịch `propnote_pro_yearly`. Apple thường tự nhận diện dữ liệu IAP nó xử lý trực tiếp — đối chiếu wording hiện hành. |
| **Identifiers** (User ID, Device ID) | KHÔNG | App không có account/User ID nào. |
| **Usage Data** (product interaction, ads data) | KHÔNG | Không có analytics SDK. |
| **Diagnostics** (crash data, performance data) | KHÔNG (tại 1.0) | Không tích hợp crash-reporting bên thứ ba. Nếu Apple tự thu thập crash log ở tầng OS (không qua code PropNote), đó là quy trình riêng của Apple, không phải PropNote "collect". |
| **Audio Data** | KHÔNG lưu | Microphone chỉ dùng tức thời cho speech-to-text. Việc nhận dạng có thể xử lý on-device hoặc qua dịch vụ giọng nói của Apple tuỳ thiết bị/phiên bản iOS — đây là xử lý theo nền tảng (platform handling), không phải PropNote tự transmit; PropNote không lưu file âm thanh. `VERIFY IN CURRENT APP STORE CONNECT FORM` nếu Apple yêu cầu khai riêng phần này do khả năng xử lý ngoài thiết bị. |
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
