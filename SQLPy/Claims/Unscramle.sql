use hospital_py
go
select claimclaimid, PolicyVersionAttributesFormType, ClaimReportedDate, StatesStateCode, LossTypeDescription,* 
from lengthofstay where claimclaimid=402690
claimclaimid	PolicyVersionAttributesFormType	ClaimReportedDate	StatesStateCode	LossTypeDescription	ClaimClaimID	ClaimReportedDate	ClaimDateClosed	LengthOfStay	ClaimClaimStatusID	ClaimStatusDescription	StatesStateCode	ClaimRoomsWithDamage	LossTypeDescription	PolicyVersionAttributesFormType	PolicyVersionAttributesOccupancyType	PolicyVersionAttributesCoverageA	ClaimMoneyReserve	ClaimMoneyLosses	ClaimMoneyLAE
402690	HO3	2018-02-16	MA	Water Damage - Non Weather Related	402690	2018-02-16	2018-04-16	59	2	Closed	MA	0	Water Damage - Non Weather Related	HO3	Owner	349442	0.00	2273.59	727.49

select claimclaimid --83909
from lengthofstay where
 PolicyVersionAttributesFormType = 'HO3'
and ClaimReportedDate = '2018-02-16'
and StatesStateCode = 'MA'
and	LossTypeDescription	= 'Water Damage - Non Weather Related'
and ClaimDateClosed	='2018-04-16'
and LengthOfStay= 59
-- and	ClaimClaimStatusID = 2 
-- and	ClaimStatusDescription = 'closed'
-- and	ClaimRoomsWithDamage = 2
-- and PolicyVersionAttributesOccupancyType = 'Owner'
-- and PolicyVersionAttributesCoverageA = 349442
-- and	ClaimMoneyReserve = 0
and	ClaimMoneyLosses = 2273.59
and	ClaimMoneyLAE =727.49

select claimclaimid, PolicyVersionAttributesFormType, ClaimReportedDate, StatesStateCode, LossTypeDescription,*
from lengthofstay where claimclaimid=402660
claimclaimid	PolicyVersionAttributesFormType	ClaimReportedDate	StatesStateCode	LossTypeDescription	ClaimClaimID	ClaimReportedDate	ClaimDateClosed	LengthOfStay	ClaimClaimStatusID	ClaimStatusDescription	StatesStateCode	ClaimRoomsWithDamage	LossTypeDescription	PolicyVersionAttributesFormType	PolicyVersionAttributesOccupancyType	PolicyVersionAttributesCoverageA	ClaimMoneyReserve	ClaimMoneyLosses	ClaimMoneyLAE
402660	HO6	2018-02-15	FL	Loss Assessment	402660	2018-02-15	2018-03-03	16	2	Closed	FL	0	Loss Assessment	HO6	Owner	65000	0.00	50.00	680.49

select claimclaimid --27495
from lengthofstay where
 PolicyVersionAttributesFormType = 'HO6'
and ClaimReportedDate = '2018-02-15'
and StatesStateCode = 'FL'
and	LossTypeDescription	= 'Loss Assessment'
and ClaimDateClosed	='2018-03-03'
and LengthOfStay= 16
-- and	ClaimClaimStatusID = 2 
-- and	ClaimStatusDescription = 'closed'
-- and	ClaimRoomsWithDamage = 2
-- and PolicyVersionAttributesOccupancyType = 'Owner'
-- and PolicyVersionAttributesCoverageA = 349442
-- and	ClaimMoneyReserve = 0
and	ClaimMoneyLosses = 50
and	ClaimMoneyLAE =680.49

select claimclaimid, PolicyVersionAttributesFormType, ClaimReportedDate, StatesStateCode, LossTypeDescription,*
from  lengthofstay where claimclaimid=402691
claimclaimid	PolicyVersionAttributesFormType	ClaimReportedDate	StatesStateCode	LossTypeDescription	ClaimClaimID	ClaimReportedDate	ClaimDateClosed	LengthOfStay	ClaimClaimStatusID	ClaimStatusDescription	StatesStateCode	ClaimRoomsWithDamage	LossTypeDescription	PolicyVersionAttributesFormType	PolicyVersionAttributesOccupancyType	PolicyVersionAttributesCoverageA	ClaimMoneyReserve	ClaimMoneyLosses	ClaimMoneyLAE
402691	HO6	2018-02-16	FL	Loss Assessment	402691	2018-02-16	2018-03-06	18	2	Closed	FL	0	Loss Assessment	HO6	Owner	65000	0.00	2000.00	950.49

select claimclaimid --61265
from lengthofstay where
 PolicyVersionAttributesFormType = 'HO6'
and ClaimReportedDate = '2018-02-16'
and StatesStateCode = 'FL'
and	LossTypeDescription	= 'Loss Assessment'
and ClaimDateClosed	='2018-03-06'
and LengthOfStay= 18
and	ClaimClaimStatusID = 2 
and	ClaimStatusDescription = 'Closed'
and	ClaimRoomsWithDamage = 0
and PolicyVersionAttributesOccupancyType = 'Owner'
and PolicyVersionAttributesCoverageA = 65000
and	ClaimMoneyReserve = 0
and	ClaimMoneyLosses = 2000
and	ClaimMoneyLAE =950.49

select claimclaimid, PolicyVersionAttributesFormType, ClaimReportedDate, StatesStateCode, LossTypeDescription,*
from  lengthofstay where claimclaimid=439181
claimclaimid	PolicyVersionAttributesFormType	ClaimReportedDate	StatesStateCode	LossTypeDescription	ClaimClaimID	ClaimReportedDate	ClaimDateClosed	LengthOfStay	ClaimClaimStatusID	ClaimStatusDescription	StatesStateCode	ClaimRoomsWithDamage	LossTypeDescription	PolicyVersionAttributesFormType	PolicyVersionAttributesOccupancyType	PolicyVersionAttributesCoverageA	ClaimMoneyReserve	ClaimMoneyLosses	ClaimMoneyLAE
439181	HO6	2018-08-15	FL	Loss Assessment	439181	2018-08-15	2018-08-21	6	2	Closed	FL	0	Loss Assessment	HO6	Owner	110000	0.00	1115.88	680.49

select claimclaimid --24849
from lengthofstay where
 PolicyVersionAttributesFormType = 'HO6'
and ClaimReportedDate = '2018-08-15'
and StatesStateCode = 'FL'
and	LossTypeDescription	= 'Loss Assessment'
and ClaimDateClosed	='2018-08-21'
and LengthOfStay= 6
and	ClaimClaimStatusID = 2 
and	ClaimStatusDescription = 'Closed'
and	ClaimRoomsWithDamage = 0
and PolicyVersionAttributesOccupancyType = 'Owner'
and PolicyVersionAttributesCoverageA = 110000
and	ClaimMoneyReserve = 0
and	ClaimMoneyLosses = 1115.88
and	ClaimMoneyLAE = 680.49

select claimclaimid, PolicyVersionAttributesFormType, ClaimReportedDate, StatesStateCode, LossTypeDescription,*
from  lengthofstay where claimclaimid=402695
claimclaimid	PolicyVersionAttributesFormType	ClaimReportedDate	StatesStateCode	LossTypeDescription	ClaimClaimID	ClaimReportedDate	ClaimDateClosed	LengthOfStay	ClaimClaimStatusID	ClaimStatusDescription	StatesStateCode	ClaimRoomsWithDamage	LossTypeDescription	PolicyVersionAttributesFormType	PolicyVersionAttributesOccupancyType	PolicyVersionAttributesCoverageA	ClaimMoneyReserve	ClaimMoneyLosses	ClaimMoneyLAE
402695	HO3	2018-02-16	FL	Wind	402695	2018-02-16	2019-01-19	337	2	Closed	FL	0	Wind	HO3	Owner	166195	0.00	39145.83	5066.09

select claimclaimid --43714
from lengthofstay where
 PolicyVersionAttributesFormType = 'HO3'
and ClaimReportedDate = '2018-02-16'
and StatesStateCode = 'FL'
and	LossTypeDescription	= 'Wind'
and ClaimDateClosed	='2019-01-19'
and LengthOfStay= 337
and	ClaimClaimStatusID = 2 
and	ClaimStatusDescription = 'Closed'
and	ClaimRoomsWithDamage = 0
and PolicyVersionAttributesOccupancyType = 'Owner'
and PolicyVersionAttributesCoverageA = 166195
and	ClaimMoneyReserve = 0
and	ClaimMoneyLosses = 39145.83
and	ClaimMoneyLAE = 5066.09