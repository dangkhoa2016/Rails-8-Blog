# Danh sách nghiệm thu thực tế bởi người dùng

> 🌐 Language / Ngôn ngữ: [English](HUMAN_TESTING.md) | **Tiếng Việt**

Sử dụng checklist này để kiểm tra trải nghiệm người dùng và các chức năng trên từng bản triển khai. CI kiểm tra mã nguồn tự động; hành vi giao diện và vận hành còn phụ thuộc môi trường thực tế.

## Chuẩn bị

Dùng tài khoản thử nghiệm và nội dung có thể xóa trên môi trường kiểm thử. Ghi SHA commit, môi trường, trình duyệt, ngôn ngữ, thời điểm và ảnh chụp đã loại bỏ thông tin riêng tư. Không thử tình huống phá hủy dữ liệu production thật.

## Kịch bản

- [ ] Đăng ký, xác nhận, đăng nhập, đặt lại mật khẩu và đăng xuất trên web.
- [ ] API sign-in cấp bearer token; sign-out đầu tiên thu hồi token; token thiếu/đã dùng lại trả 401; endpoint bảo vệ khác từ chối JWT bị thu hồi.
- [ ] So sánh quyền admin, author, reader và guest; kiểm tra thao tác trái quyền bị chặn.
- [ ] Tạo, sửa, xem trước, xuất bản, lên lịch và soft-delete bài viết.
- [ ] Kiểm tra bài chưa công bố, chưa đến lịch hoặc đã bị xóa mềm không lộ trên public/API.
- [ ] Sửa/xem cả bảy locale; kiểm tra thay đổi slug và fallback đa ngôn ngữ.
- [ ] Tải ảnh ActionText và slideshow; kiểm tra ranh giới ảnh gốc R2 và ảnh dẫn xuất Cloudinary.
- [ ] Tạo, sắp xếp, bản địa hóa và xóa slide.
- [ ] Kiểm tra bình luận, reaction, category và tag.
- [ ] Kiểm tra rate limiting, maintenance, audit history và quyền khôi phục.
- [ ] Restart container; kiểm tra trạng thái lưu DB và job vẫn còn, không dựa vào ổ đĩa tạm.
- [ ] Kiểm tra trình duyệt desktop/mobile, bàn phím và accessibility cơ bản.

## Ghi nhận kết quả

Đánh dấu PASS/FAIL/CHƯA CHẠY cho từng trường hợp, kèm bằng chứng và issue. Kiểm tra lại sau khi sửa và chạy regression. **Không tuyên bố nghiệm thu hoàn tất khi chưa thật sự chạy các kịch bản.**

Bằng chứng kiểm thử chỉ có giá trị cho môi trường và SHA tương ứng. Xem [giới hạn](LIMITATIONS.vi.md) và [hướng dẫn triển khai](DEPLOYMENT.vi.md).
