# ***Command to run collocation:***


## **-- Running for CYGNSS:**

 		clear all; Combining\_Cyg "path to configuration.cfg file"

## **Describing the configuration\_sample.cfg:**


*  	processMode :	processMode=1 → process CyGNSS data extracted and saved in one single file

 				processMode=2 → process CyGNSS data extracted and saved in daily format

*  	Target\_Resolution ------> desire resolution of collocated data (currently just 25km is working)

*  	stratDay \& endDay ----> should be in 'yyyymmdd' format

*  	smap and modis\_path -----> path to the SMAP or MODIS files. SMAP files should follow a structure like this:

 						smap/modis path

 						    | year

 						        | month

 						            | day


*  	cygnss\_path ------> path to the extracted CYGNSS files, extracted in daily format, (it is a path to a directory). It is for processmode=2

*  	cygnss\_file ------> path to the extracted CYGNSS file (it is a path of a single extracted file, a .mat file). It is for processmode=1

*  	product\_path ------> path to save the collocated data

*  	SMAPQualityFlagFilter --------> "yes" if you want to apply SMAP quality flag (recommended and succsessful retrieval)
  "no" means without applying any SMAP quality flag

*  	CyGNSS\_processing ---------> This option was added to faster process if I just wanted to pre-process again the SMAP data. Could  be "yes" or "no"

*  	SMAP\_resolution ------> it is the resolution of raw SMAP data. Could be 9 or 36




## **-- Running for HydroGNSS:**

 		clear all; Combining\_Hydro "path to configuration_Hydro.cfg file"

## **Describing the configuration\_Hydro\_sample.cfg:**

*  	Target\_Resolution ------> desire resolution of collocated data (currently just 25km is working)

*  	stratDay \& endDay ----> should be in 'yyyymmdd' format

*  	smap and modis\_path -----> path to the SMAP or MODIS files. SMAP files should follow a structure like this:

 						smap/modis path

 						    | year

 						        | month

 						            | day


*  	hydro\_file ------> path to the extracted HydroGNSS file (it is a path of a single extracted file, a .mat file)

*  	product\_path ------> path to save the collocated data

*  	SMAPQualityFlagFilter --------> "yes" if you want to apply SMAP quality flag (recommended and succsessful retrieval)
  "no" means without applying any SMAP quality flag

*  	hydro\_processing ---------> This option was added to faster process if I just wanted to pre-process again the SMAP data. Could  be "yes" or "no"

*  	SMAP\_resolution ------> it is the resolution of raw SMAP data. Could be 9 or 36
