# TinEduPrep Content Feed

Thư mục này là nguồn phát hành nội dung cho GitHub Pages.

- Tăng `version` trong `manifest.json` mỗi khi có nội dung mới.
- Workflow sẽ tự copy ba file JSON trong `TinEduPrep/Resources` lên Pages.
- URL manifest sau khi bật Pages có dạng:
  `https://<owner>.github.io/<repository>/content/manifest.json`

Sau khi có URL thật, đặt URL đó vào build setting `STUDY_CONTENT_MANIFEST_URL` của app.
