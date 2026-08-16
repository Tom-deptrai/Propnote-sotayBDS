# Hướng dẫn host công khai Privacy / Terms / Support

App Store Connect bắt buộc 1 **Privacy Policy URL công khai** (ai cũng
truy cập được, không cần đăng nhập), và khuyến nghị có thêm Support URL.
Cả 3 trang đã sẵn sàng để publish cùng lúc:

- `release/app_store/1.0.0/privacy-policy.html`
- `release/app_store/1.0.0/terms-of-use.html`
- `release/app_store/1.0.0/support.html`

Cả 3 trang trỏ chéo lẫn nhau (link tương đối), nên publish chung 1 thư mục
để các link nội bộ hoạt động đúng. Có sẵn bộ gọn `release/app_store/1.0.0/site/`
(`index.html`, `privacy.html`, `terms.html`, `support.html`) — dùng bộ này
nếu muốn publish nguyên 1 site nhỏ có trang chủ, hoặc dùng 3 file gốc ở
trên nếu chỉ cần từng URL riêng lẻ.

Email hỗ trợ đã điền sẵn trong cả 3 file: `Timeforwork789@icloud.com`.
Không cần sửa gì thêm trước khi publish.

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

### Lựa chọn A — publish cả bộ site gọn (`site/`), có trang chủ

```bash
git checkout --orphan gh-pages
git rm -rf .
cp -r "release/app_store/1.0.0/site/." .
git add index.html privacy.html terms.html support.html
git commit -m "docs: publish privacy/terms/support site"
git push origin gh-pages
```

URL sau khi publish (GitHub Pages cần 1-2 phút để deploy lần đầu):
```
https://tom-deptrai.github.io/Propnote-sotayBDS/            (trang chủ)
https://tom-deptrai.github.io/Propnote-sotayBDS/privacy.html
https://tom-deptrai.github.io/Propnote-sotayBDS/terms.html
https://tom-deptrai.github.io/Propnote-sotayBDS/support.html
```

### Lựa chọn B — publish từ thư mục `/docs` trên `main` (giữ nguyên lịch sử)

```bash
mkdir -p docs
cp -r "release/app_store/1.0.0/site/." docs/
git add docs/
git commit -m "docs: publish privacy/terms/support site"
git push origin main
```

Trong GitHub Settings → Pages, chọn **Source: Deploy from a branch**,
branch **main**, folder **/docs**. URL giống lựa chọn A ở trên.

---

## Cách khác: Netlify (nếu muốn domain gọn hơn, kéo-thả không cần git)

1. Vào [app.netlify.com](https://app.netlify.com) → đăng nhập (có thể dùng
   tài khoản GitHub sẵn có).
2. Kéo-thả cả thư mục `release/app_store/1.0.0/site/` vào ô "Deploy
   manually" trên trang Netlify.
3. Netlify cấp ngay 1 URL dạng `https://random-name-123.netlify.app`, kèm
   `/privacy.html`, `/terms.html`, `/support.html`. Có thể đổi tên
   subdomain trong **Site settings → Change site name**.

## Cách khác: Cloudflare Pages

Tương tự Netlify — vào [pages.cloudflare.com](https://pages.cloudflare.com),
tạo project mới, upload trực tiếp thư mục `site/`, nhận URL dạng
`https://propnote.pages.dev` kèm `/privacy.html`, `/terms.html`, `/support.html`.

---

## Sau khi có URL

1. Mở cả 3 URL (privacy/terms/support) trên trình duyệt, xác nhận trang
   hiển thị đúng, đọc được trên điện thoại lẫn máy tính (đã responsive),
   và các link chéo giữa 3 trang hoạt động đúng.
2. Copy URL Privacy Policy, dán vào ô **Privacy Policy URL** trong App
   Store Connect (mục App Information).
3. Copy URL Support, dán vào ô **Support URL** trong App Store Connect.
4. Cập nhật lại 3 URL này vào `APP_STORE_METADATA_VI.md` và
   `USER_APP_STORE_STEPS.md` (đang để các placeholder tương ứng).

**Lưu ý quan trọng:** Claude sẽ KHÔNG tự publish các trang này lên Internet —
đây là hành động hiển thị công khai, cần bạn tự thực hiện 1 trong các cách
trên (hoặc yêu cầu Claude thực hiện cụ thể nếu bạn muốn, ở 1 phiên làm việc
riêng có xác nhận rõ ràng).
