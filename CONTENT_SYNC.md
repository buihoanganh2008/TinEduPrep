# Cập nhật nội dung từ xa

TinEduPrep luôn có dữ liệu JSON tích hợp sẵn để hoạt động offline. Khi cấu hình một manifest HTTPS, app sẽ kiểm tra nội dung mới khi mở app hoặc quay lại foreground, sau đó lưu bản cập nhật vào bộ nhớ cục bộ.

## Cấu trúc manifest

Đặt một file `manifest.json` trên máy chủ:

```json
{
  "version": "1.1.0",
  "lessons": "lessons.json",
  "questions": "questions.json",
  "practicalCases": "practical_cases.json"
}
```

Ba file JSON được trỏ tới phải cùng tuân theo cấu trúc của các file trong `TinEduPrep/Resources`.

## Bật nguồn cập nhật

Trong Xcode, đặt build setting `STUDY_CONTENT_MANIFEST_URL` thành URL HTTPS của manifest, ví dụ:

```text
https://your-domain.example/tineduprep/manifest.json
```

Khi phát hành nội dung mới, tăng `version` theo dạng số phiên bản, ví dụ `1.0.0` thành `1.1.0`. App chỉ áp dụng phiên bản lớn hơn, kiểm tra dữ liệu và giữ bản cũ nếu tải thất bại.

## Dùng GitHub Pages

Project đã có workflow `.github/workflows/publish-content-pages.yml`. Sau khi đưa project lên GitHub:

1. Vào repository **Settings → Pages** và chọn **GitHub Actions** làm nguồn deploy.
2. Push branch `main` hoặc chạy workflow `Publish TinEduPrep content` thủ công.
3. Manifest sẽ có tại:
   `https://<owner>.github.io/<repository>/content/manifest.json`
4. Đặt URL này vào build setting `STUDY_CONTENT_MANIFEST_URL`, rồi build lại app.

Sau đó, chỉ cần chỉnh nội dung trong `TinEduPrep/Resources` và tăng phiên bản trong `ContentFeed/manifest.json`; GitHub Actions sẽ tự publish feed mới.
