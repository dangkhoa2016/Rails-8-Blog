# Bản quyền và nguồn gốc tài sản đi kèm

> 🌐 Language / Ngôn ngữ: [English](ASSET_PROVENANCE.md) | **Tiếng Việt**

## Phạm vi

Rails 8 Blog có một số hình ảnh được lưu trực tiếp trong Git. [MIT License](../LICENSE) của dự án **không** chứng minh quyền sở hữu ảnh lấy từ bên khác. Đây là bản kiểm kê thận trọng, **không** có nghĩa tất cả quyền sử dụng đã được xác minh độc lập.

## Hình minh họa tài khoản được tạo riêng

Năm hình minh họa tài khoản (`confirmation`, `forgot-password`, `login`, `profile`, `registration`) được vẽ riêng dưới dạng hình học, có [mã nguồn SVG có thể chỉnh sửa](../artwork/auth-illustrations/) và bản xuất PNG cho giao diện. Hình `unlock.png` được tạo riêng cho dự án dưới dạng ảnh raster nền trong suốt, không có mã nguồn vector có thể chỉnh sửa. Bản vẽ `unlock.svg` cũ có nội dung khác và không được phân phối. Sáu hình này không nhúng ảnh stock từ bên thứ ba.

Ba favicon được giữ nguyên. Người duy trì sẽ cung cấp nguồn gốc, giấy phép và thông tin ghi công tương ứng. Checksum hay giấy phép mã nguồn không tự chứng minh quyền phân phối ảnh.

## Hình ảnh đang được Git track

| Tài sản | SHA-256 nhận diện nội dung |
|---|---|
| `app/assets/images/confirmation.png` | `9823732e10bb103cd139f4bff03a8072cc16e4cc89dbd62dca4f214b0554b61d` |
| `app/assets/images/forgot-password.png` | `40af82ac09e17ea8e205c933dc0331fb48aac2373ea90d7aa5281fea42bd4aa2` |
| `app/assets/images/login.png` | `70006973866559694a3cbc509f7f367bb13332a11c2f3a6aafb657a8d3968356` |
| `app/assets/images/profile.png` | `ece4cab6a265aa3675bb15c311dfdf065e8bab6b571c319afb1b792ae5c35232` |
| `app/assets/images/registration.png` | `51f9ecb4ccf0a947e217e967c74a34304ad7f2a85e890725b2f65683cdc51a30` |
| `app/assets/images/unlock.png` | `1aaeec8ff972f641fbb3add6c699c3f44441623f1c76f09c1e9ff6dc11f9d8cc` |
| `public/favicon.ico` | `d9bd8fb4af8c9ac24c11b25afa6d0f592cda023e533cd0733040f474a9356452` |
| `public/favicon.png` | `7e0e75253444569c29ebaa7cfd42d9cdf494cfc37f34e84338a9a65e1eb7f37c` |
| `public/favicon.svg` | `1aa1db6bc9963ca0aa0ff9ff9b25a11bde9e4ada895f640fcc47188e42f589dc` |

SHA-256 xác định byte đang kiểm tra; **checksum không phải giấy phép**. Kiểm tra file nguồn không đủ để kết luận ai tạo ảnh, giấy phép stock hoặc quyền phân phối lại.

## Kiểm tra trước xuất bản

- [ ] Xác minh nguồn gốc và quyền phân phối ba favicon còn giữ nguyên.
- [ ] Nếu là tài sản bên ngoài, giữ tên tác giả, URL nguồn, mã giấy phép và yêu cầu ghi công.
- [ ] Thay thế hoặc xóa tài sản không có quyền phân phối thích hợp.
- [ ] Ghi nhận font, icon, sơ đồ hoặc media đi kèm mới trong tương lai.
- [ ] Xác minh người tải nội dung lên có quyền sử dụng.

Nguồn gốc ba favicon **chưa được xác minh**. Xem thêm [Thông báo bên thứ ba](../THIRD_PARTY_NOTICES.vi.md).
