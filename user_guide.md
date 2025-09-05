#### **Command to run collocation:**



 		clear all; Combining "path to configuration.cfg file"









#### **Describing the configuration\_samp.cfg:**



*  	processingmode :
  processMode=1 → process CyGNSS data extracted and saved in one single file

 			processMode=2 → process CyGNSS data extracted and saved in daily format



*  	Target\_Resolution ------> desire resolution of collocated data (currently just 25km is working)



*  	stratDay \& endDay ----> should be in 'yyyymmdd' format





*  	smap\_path -----> path to the SMAP files. SMAP files should follow a structure like this:

 

 						smap\_path

 						|

 						|--------2021.01.01

 						|--------2021.01.02

 						|--------2021.01.02

 						.

 						.

 						.



*  	cygnss\_path ------> path to the CYGNSS files extracted in daily format. It is for processmode=2



*  	cygnss\_path ------> path to the CYGNSS file (a single extracted file). It is for processmode=1



*  	product\_path ------> path to save the collocated data



*  	SMAPQualityFlagFilter --------> "yes" if you want to apply SMAP quality flag (recommended and succsessful retrieval)
  "no" means without applying any SMAP quality flag



*  	CyGNSS\_processing ---------> This option was added to faster process if I just wanted to pre-process again the SMAP data. Could  be "yes" or "no"



*  	SMAP\_resolution ------> it is the resolution of raw SMAP data. Could be 9 or 36
