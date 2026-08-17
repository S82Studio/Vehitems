Locales = Locales or {}

Locales['vi'] = {
    -- Hop thoai xac nhan
    ['confirm_header']  = 'Xác nhận sử dụng vật phẩm',
    ['confirm_content'] = 'Đây là vật phẩm đặc biệt, bạn sẽ nhận được quyền sở hữu phương tiện này. Hãy chọn nơi rộng rãi không có vật cản trở để sử dụng vật phẩm.',
    ['confirm_confirm'] = 'Sử dụng',
    ['confirm_cancel']  = 'Hủy bỏ',

    -- Thanh tien trinh
    ['progress_label'] = 'Đang triển khai phương tiện...',

    -- Loi phia client
    ['err_busy']              = 'Bạn đang trong quá trình sử dụng vật phẩm khác!',
    ['err_in_vehicle']        = 'Không thể sử dụng vật phẩm khi đang ở trong xe!',
    ['err_in_interior']       = 'Không thể sử dụng vật phẩm trong nhà / nội thất!',
    ['err_too_many_vehicles'] = 'Có quá nhiều xe xung quanh. Vui lòng di chuyển đến nơi rộng rãi hơn!',
    ['err_too_many_objects']  = 'Có quá nhiều vật cản xung quanh. Vui lòng tìm chỗ thoáng hơn!',
    ['err_invalid_position']  = 'Vị trí không hợp lệ. Vui lòng thử lại ở nơi khác!',
    ['err_interrupted']       = 'Quá trình sử dụng bị gián đoạn!',

    -- Loi phia server
    ['err_cannot_identify']  = 'Không thể xác định người chơi!',
    ['err_cooldown']         = 'Bạn cần chờ %s nữa mới có thể sử dụng vật phẩm này.',
    ['err_already_flow']     = 'Bạn đang trong quá trình sử dụng vật phẩm!',
    ['err_no_item']          = 'Bạn không có vật phẩm này!',
    ['err_invalid_session']  = 'Phiên sử dụng vật phẩm không hợp lệ!',
    ['err_invalid_coords']   = 'Tọa độ spawn không hợp lệ!',
    ['err_unsupported_item'] = 'Vật phẩm không được hỗ trợ!',
    ['err_item_gone']        = 'Bạn không còn vật phẩm này!',
    ['err_register_failed']  = 'Không thể đăng ký xe: %s',
    ['err_spawn_failed']     = 'Lỗi khi spawn xe, đã hoàn tác!',
    ['err_no_bridge']        = 'Script không nhận diện được framework/inventory phù hợp. Vui lòng liên hệ admin.',

    -- Thanh cong
    ['success_received'] = 'Đã nhận xe %s thành công! Biển số: %s',

    -- Dinh dang thoi gian
    ['time_seconds']         = '%d giây',
    ['time_minutes']         = '%d phút',
    ['time_minutes_seconds'] = '%d phút %d giây',
}
