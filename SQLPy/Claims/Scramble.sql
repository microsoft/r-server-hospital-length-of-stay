use Hospital_Py
go

drop table if exists atlas.claimlengthofstay

drop table if exists scramble

create table scramble (scramble int identity(1,1) primary key clustered, claimclaimid int)
insert scramble (claimclaimid) 
select claimclaimid from LengthOfStay 

update a 
set a.claimclaimid = b.scramble
from LengthOfStay as a 
inner join scramble as b
on a.claimclaimid = b.claimclaimid

select * from LengthOfStay

update a 
set a.claimclaimid = b.scramble
from forest_prediction as a 
inner join scramble as b
on a.claimclaimid = b.claimclaimid

select * from forest_prediction

update a 
set a.claimclaimid = b.scramble
from train_id as a 
inner join scramble as b
on a.claimclaimid = b.claimclaimid

select * from train_id

update a 
set a.claimclaimid = b.scramble
from QueryClaim as a 
inner join scramble as b
on a.claimclaimid = b.claimclaimid

select * from QueryClaim

update a 
set a.claimclaimid = b.scramble
from Boosted_Prediction as a 
inner join scramble as b
on a.claimclaimid = b.claimclaimid

select * from Boosted_Prediction


update a 
set a.claimclaimid = b.scramble
from Forest_Prediction as a 
inner join scramble as b
on a.claimclaimid = b.claimclaimid

select * from Forest_Prediction

drop table if exists scramble
