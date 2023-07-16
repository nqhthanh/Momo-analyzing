-- Tạo bảng Loyalty Ranking, Tạo bảng cashback để maping, join Loyalty Benefits và Loyalty Rankings
create view Transaction_test as
with lp as (
select *,
Case
	when Year (Date) = 2022 and Service_Group = 'supermarket' then GMV/1000
	when Year (Date) = 2022 and Service_Group = 'data' then (GMV*10)/1000
	when Year (Date) = 2022 and Service_Group = 'cvs' then GMV/1000
	when Year (Date) = 2022 and Service_Group = 'marketplace' then GMV/1000
	when Year (Date) = 2022 and Service_Group = 'Coffee chains and Milk tea' then GMV/1000
	when Year (Date) = 2022 and Service_Group = 'Offline Beverage' then GMV/1000
	else 0
End as LoyaltyPoints
from Transactions ), lp_fx as (
	select *,
	case 
		when Service_Group = 'supermarket' and LoyaltyPoints > 500 then 500
		when Service_Group = 'data' and LoyaltyPoints > 1000 then 1000
		when Service_Group = 'cvs' and LoyaltyPoints > 300 then 300
		when Service_Group = 'marketplace' and LoyaltyPoints > 500 then 500
		when Service_Group = 'Coffee chains and Milk tea' and LoyaltyPoints > 500 then 500
		when Service_Group = 'Offline Beverage' and LoyaltyPoints > 300 then 300
	else
	LoyaltyPoints
end as Loyalty_Points
from lp
), lp_calc as (
	select [DATE], Order_id, NEWVERTICAL_Merchant, MerchantID, User_id, GMV, Service_Group, SUM(Loyalty_Points) as Loyalty_Points
	from lp_fx
	where [DATE] >= DATEADD(DAY,-30,[DATE]) --Giải quyết vấn đề hạn điểm sau 30 ngày
	group by User_id, Order_id, [DATE],NEWVERTICAL_Merchant, MerchantID, User_id, GMV, Service_Group
), total_lp as (
	select User_id, [Date], Service_Group, SUM(Loyalty_Points) as Calculated_Points
	from lp_calc
	where [DATE] >= DATEADD(DAY,-30,[DATE]) --Giải quyết vấn đề hạn điểm sau 30 ngày
	group by User_id, [DATE], Service_Group
), ltr as (
select *,
case 
	when Calculated_Points >= 1 and Calculated_Points <= 999 then 'STANDARD'
	when Calculated_Points >= 1000 and Calculated_Points <= 1999 then 'SILVER'
	when Calculated_Points >= 2000 and Calculated_Points <= 4999 then 'GOLD'
	when Calculated_Points >= 5000 then 'DIAMOND'
end as Rank_name
from total_lp
where Calculated_Points > 0), fx_ltr as (
	select *,
	case
		when Service_Group = 'cvs' and Rank_name = 'STANDARD' then 1
		when Service_Group = 'cvs' and Rank_name = 'SILVER' then 2
		when Service_Group = 'cvs' and Rank_name = 'GOLD' then 3
		when Service_Group = 'cvs' and Rank_name = 'DIAMOND' then 4
		when Service_Group = 'Offline Beverage' and Rank_name = 'STANDARD' then 1
		when Service_Group = 'Offline Beverage' and Rank_name = 'SILVER' then 2
		when Service_Group = 'Offline Beverage' and Rank_name = 'GOLD' then 3
		when Service_Group = 'Offline Beverage' and Rank_name = 'DIAMOND' then 4
		when Service_Group = 'data' and Rank_name = 'STANDARD' then 1
		when Service_Group = 'data' and Rank_name = 'SILVER' then 2
		when Service_Group = 'data' and Rank_name = 'GOLD' then 3
		when Service_Group = 'data' and Rank_name = 'DIAMOND' then 4
		when Service_Group = 'marketplace' and Rank_name = 'STANDARD' then 1
		when Service_Group = 'marketplace' and Rank_name = 'SILVER' then 2
		when Service_Group = 'marketplace' and Rank_name = 'GOLD' then 3
		when Service_Group = 'marketplace' and Rank_name = 'DIAMOND' then 4
		when Service_Group = 'supermarket' and Rank_name = 'STANDARD' then 1
		when Service_Group = 'supermarket' and Rank_name = 'SILVER' then 2
		when Service_Group = 'supermarket' and Rank_name = 'GOLD' then 3
		when Service_Group = 'supermarket' and Rank_name = 'DIAMOND' then 4
		else 
		1
	end as ClassID
	from ltr)
select fl.*, ISNULL(cashback,0) as '%cashback'
from fx_ltr fl 
left join LoyaltyBenefits lb on fl.ClassID = lb.Class_ID and fl.Service_Group = lb.[Group]
--Kiểm tra dữ liệu của bảng Transaction sau khi triển khai dự án
GO
select *
from Transaction_test
--function check userID theo ngày giao dịch
go
create function fnUserID (
	@userid int
)
returns TABLE
as return
(
	select *
	from Transaction_test
	where User_id = @userid
)
go
-- xóa function: drop function fnUserID
--Test function
go
select * from fnUserID('136825')
go
--function tính tổng điểm theo mã người dùng
create function fntotalpoints (
	@userid int
)
returns float
as
begin
	declare @tongdiem int
	select @tongdiem = sum(Calculated_Points)
	from Transaction_test
	where User_id = @userid
	return @tongdiem
END
go
-- xóa function : drop function fntotalpoints
--Test
declare @kq INT
exec @kq = fntotalpoints '162483'
print @kq