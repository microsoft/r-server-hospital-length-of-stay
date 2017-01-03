DROP TABLE IF EXISTS [dbo].[LengthOfStay]
CREATE TABLE [dbo].[LengthOfStay](
	    [eid] [int] NOT NULL,
	    [vdate] [varchar](255),
	    [rcount] [varchar](2) NULL,
	    [gender] [varchar](1) NULL,
	    [dialysisrenalendstage] [varchar](1) NULL,
	    [asthma] [varchar](1) NULL,
	    [irondef] [varchar](1) NULL,
	    [pneum] [varchar](1) NULL,
	    [substancedependence] [varchar](1) NULL,
	    [psychologicaldisordermajor] [varchar](1) NULL,
	    [depress] [varchar](1) NULL,
	    [psychother] [varchar](1) NULL,
	    [fibrosisandother] [varchar](1) NULL,
	    [malnutrition] [varchar](1) NULL,
	    [hemo] [float] NULL,
	    [hematocritic] [float] NULL,
	    [neutrophils] [float] NULL,
	    [sodium] [float] NULL,
	    [glucose] [float] NULL,
	    [bloodureanitro] [float] NULL,
	    [creatinine] [float] NULL,
	    [bmi] [float] NULL,
	    [pulse] [float] NULL,
	    [respiration] [float] NULL,
	    [secondarydiagnosisnonicd9] [varchar](2) NULL,
	    [discharged] [varchar](255) NULL,
	    [facid] [varchar](3) NULL,
	    [lengthofstay] [int] NULL
    )

CREATE CLUSTERED COLUMNSTORE INDEX length_cci ON LengthOfStay WITH (DROP_EXISTING = OFF);

