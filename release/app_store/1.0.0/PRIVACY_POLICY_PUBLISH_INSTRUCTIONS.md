# Hướng dẫn host công khai `privacy-policy.html`

App Store Connect bắt buộc 1 **Privacy Policy URL công khai** (ai cũng
truy cập được, không cần đăng nhập). File `privacy-policy.html` trong cùng
thư mục này đã sẵn sàng để upload — chỉ cần chọn 1 trong các cách dưới đây.

**Trước khi publish:** điền `[EMAIL HỖ TRỢ CẦN ĐIỀN]` trong file HTML thành
email hỗ trợ thật của bạn.

---

## Cách nhanh nhất: GitHub Pages (miễn phí, dùng luôn repo hiện tại)

Repo đã có sẵn trên GitHub (`Tom-deptrai/Propnote-sotayBDS`) — GitHub Pages
là cách nhanh nhất vì không cần tài khoản mới.

1. Vào GitHub repo → **Settings** → **Pages**.
2. Ở **Source**, chọn **Deploy from a branch**.
3. Chọn branch (khuyến nghị: tạo branch riêng `gh-pages`, hoặc dùng `main`
   với thư mục `/docs` nếu muốn tách biệt — xem lựa chọn B dưới).
4. Bấm **Save**. GitHub sẽ cấp URL dạng:
   ```
   https://tom-deptrai.github.io/Propnote-sotayBDS/
   ```

### Lựa chọn A — publish riêng 1 file, gọn nhất

```bash
git checkout --orphan gh-pages
git rm -rf .
cp "release/app_store/1.0.0/privacy-policy.html" index.html
git add index.html
git commit -m "docs: publish privacy policy page"
git push origin gh-pages
```

URL sau khi publish (GitHub Pages cần 1-2 phút để deploy lần đầu):
```
https://tom-deptrai.github.io/Propnote-sotayBDS/
```

### Lựa chọn B — publish từ thư mục `/docs` trên `main` (giữ nguyên lịch sử)

```bash
mkdir -p docs
cp "release/app_store/1.0.0/privacy-policy.html" docs/index.html
git add docs/index.html
git commit -m "docs: publish privacy policy page"
git push origin main
```

Trong GitHub Settings → Pages, chọn **Source: Deploy from a branch**,
branch **main**, folder **/docs**.

URL: `https://tom-deptrai.github.io/Propnote-sotayBDS/`

---

## Cách khác: Netlify (nếu muốn domain gọn hơn, kéo-thả không cần git)

1. Vào [app.netlify.com](https://app.netlify.com) → đăng nhập (có thể dùng
   tài khoản GitHub sẵn có).
2. Kéo-thả file `privacy-policy.html` (đổi tên thành `index.html` trước khi
   kéo) vào ô "Deploy manually" trên trang Netlify.
3. Netlify cấp ngay 1 URL dạng `https://random-name-123.netlify.app`. Có
   thể đổi tên subdomain trong **Site settings → Change site name**.

## Cách khác: Cloudflare Pages

Tương tự Netlify — vào [pages.cloudflare.com](https://pages.cloudflare.com),
tạo project mới, upload trực tiếp file HTML (đổi tên `index.html`), nhận
URL dạng `https://propnote-privacy.pages.dev`.

---

## Sau khi có URL

1. Mở URL vừa publish trên trình duyệt, xác nhận trang hiển thị đúng, đọc
   được trên điện thoại lẫn máy tính (trang đã responsive sẵn).
2. Copy URL đó, dán vào ô **Privacy Policy URL** trong App Store Connect
   (mục App Information) — cũng là URL cần điền vào
   `APP_STORE_METADATA_VI.md` (đang để placeholder
   `[PRIVACY POLICY URL CẦN ĐIỀN]`).

**Lưu ý quan trọng:** Claude sẽ KHÔNG tự publish trang này lên Internet —
đây là hành động hiển thị công khai, cần bạn tự thực hiện 1 trong các cách
trên (hoặc yêu cầu Claude thực hiện cụ thể nếu bạn muốn, ở 1 phiên làm việc
riêng có xác nhận rõ ràng).
