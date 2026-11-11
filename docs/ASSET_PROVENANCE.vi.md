# Bản quyền và nguồn gốc tài sản đi kèm

> 🌐 Language / Ngôn ngữ: [English](ASSET_PROVENANCE.md) | **Tiếng Việt**

## Phạm vi

Rails 8 Blog có một số hình ảnh được lưu trực tiếp trong Git. [MIT License](../LICENSE) của dự án **không** chứng minh quyền sở hữu ảnh lấy từ bên khác. Đây là bản kiểm kê thận trọng, **không** có nghĩa tất cả quyền sử dụng đã được xác minh độc lập.

## Hình minh họa tài khoản được tạo riêng

Sáu hình `confirmation.png`, `login.png`, `registration.png`, `forgot-password.png`, `profile.png` và `unlock.png` được tạo riêng cho dự án dưới dạng PNG nền trong suốt, không có mã nguồn vector tương ứng. Kích thước vùng minh họa được đồng bộ để sử dụng trong bố cục Devise. Các bản SVG cũ không tương ứng với PNG hiện tại không được phân phối. Bộ hình minh họa không nhúng ảnh stock bên thứ ba do dự án đưa vào.

Ba favicon được giữ nguyên. Người duy trì sẽ cung cấp nguồn gốc, giấy phép và thông tin ghi công tương ứng. Checksum hay giấy phép mã nguồn không tự chứng minh quyền phân phối ảnh.

## Hình ảnh đang được Git track

| Tài sản | SHA-256 nhận diện nội dung |
|---|---|
| `app/assets/images/confirmation.png` | `c6ca1486fbb04825f0d4dc9f70bf2b050e91f05539060688b93fce616a199a7e` |
| `app/assets/images/forgot-password.png` | `f2f9c59a272d5656e64678e5a7841f5743fc971e7658f72adf4f1484ba1add70` |
| `app/assets/images/login.png` | `6a9e2d571c1def51a553ca2fc3911b63ec54d26bd6695253fe92e4a7237abc8c` |
| `app/assets/images/profile.png` | `f35d76aef6160d41d40a53039e136ae3a4caf6b5997172f18c34c97b312ea3bd` |
| `app/assets/images/registration.png` | `a5846620bb5682fe2df25d711859659c7ac9ccc0208ec567560c69b693f1398c` |
| `app/assets/images/unlock.png` | `9f3141cb2d97b426b214289d6a450be31c138c691840920f96eeafe0228392ae` |
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
