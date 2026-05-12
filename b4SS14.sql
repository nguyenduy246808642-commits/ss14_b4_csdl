-- Đề xuất  chiến lược
--  Chiến lược 1: UPDATE trực tiếp + bắt lỗi (Exception only)
-- Nhược điểm:
-- Có thể đã trừ ví rồi mới lỗi
-- Phụ thuộc hoàn toàn vào exception
-- Khó kiểm soát logic nghiệp vụ

--  Chiến lược 2: Kiểm tra trước → rồi mới xử lý
-- Ưu điểm:
-- Không bao giờ làm sai nghiệp vụ
-- Không gây âm tiền
-- Chủ động kiểm soát logic
--  Nhược:
-- Cần thêm bước kiểm tra

-- Luồng xử lý
-- Bắt đầu transaction
-- Lấy số dư ví bệnh nhân
-- Kiểm tra:
-- Nếu amount <= 0 => lỗi
-- Nếu wallet < amount => rollback
-- Nếu hợp lệ:
-- Trừ tiền ví
-- Giảm nợ
-- Commit
-- Trả message
create database b4ss14;
use b4ss14;

CREATE TABLE wallets (
    patient_id INT PRIMARY KEY,
    balance DECIMAL(10,2)
);

CREATE TABLE debts (
    patient_id INT PRIMARY KEY,
    debt DECIMAL(10,2)
);

INSERT INTO wallets VALUES (1, 100000);
INSERT INTO debts VALUES (1, 200000);

delimiter $$

create procedure one_touch_payment(
    in p_patient_id int,
    in p_amount decimal(10,2),
    out p_message varchar(255)
)
begin

    declare v_balance decimal(10,2);

-- -- nếu như xảy ra lỗi thì sẽ rollback luôn tại đay
    declare exit handler for sqlexception
    begin
        rollback;
        set p_message = 'lỗi hệ thống';
    end;

    start transaction;

    select balance
    into v_balance
    from wallets
    where patient_id = p_patient_id;

    if p_amount <= 0 then
        rollback;
        set p_message = 'số tiền không hợp lệ';

    elseif v_balance < p_amount then
        rollback;
        set p_message = 'số dư ví không đủ';

    else
        
        update wallets
        set balance = balance - p_amount
        where patient_id = p_patient_id;

    
        update debts
        set debt = debt - p_amount
        where patient_id = p_patient_id;

        commit;
        set p_message = 'thanh toán thành công';
    end if;

end $$

delimiter ;

call one_touch_payment(1, 50000, @msg);
select @msg;

-- lỗi
call one_touch_payment(1, 999999, @msg);
select @msg;

-- tiền am
call one_touch_payment(1, -50000, @msg);
select @msg;
