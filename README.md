# DriverDeployment

## Context
While at [company I used to work for] we used Configuation Manager to image new machines and reimage existing machines.  Most of those machines were from HP.  Part of the image deployment involves installing drivers from HP at two separate steps in the imaging process.  We then used the same packages created for installing drivers during imaging to push updated drivers to the existing machines in the field to keep them current.  This project includes the scripts we used to create, update, deploy, and monitor those packages, and the documents written on how to use the scripts and drivers.  They were written for whoever whould be performing these steps after I left, so the reader would have some knowlege of the environment and how our imaging process worked.  I know these scripts may not be the most efficient, but they got the job done.


## Adding a New HP Model to the Image.docx
These instructions detail how to use some of the HP tools to get injection drivers from HP and add them to the image deployment task sequence, starting with just the name of a new model.  At times we didn't even have access to a sample machine of that model to test when preparing the drivers.  It then describes which script to run to get the HPIA drivers downloaded and preparing the Configuration Manager infrastructure to install these drivers during imaging.  It also includes a section about configuring the BIOS, which is not relavent to the driver installation.  The scripts would be run in order to create the SCCM infrastructure, download the drivers, and import the drivers in to SCCM as packages.

## make_new_model_collections.ps1
Given a new model name, create the appropriate collections for detection and HPIA deployment.
1.  All HP <model> under either All PCs\All Laptops or All PCs\All Desktops (or All PCs\All Tablets)
2.  Query rules for new collection using both full and short names for model
Activity is logged in file at path in $LogFileSCCM
Customizations required:
	SITE: for ConfigMgr site code (3 times: lines 44, 61, & 62)
	\\​server\share for path to server to save downloaded drivers (1 time: line 45)

## HPIA_sync_drivers.ps1
Given model table, create the appropriate folder(s) and download the latest drivers from HP to it
Drivers are downloaded to $RepositoryPath
Summary of downloaded files in drivers.csv within folder
Activity is logged to file at path in $LogFile
Customizations required:
	\\​server\share for path to server to save downloaded drivers (1 time: line 111)
	Mail.domain.com for name of mail server (1 time: line 245)
	recipient@​domain.com for name of email recipient (2 times: line 246, 249)
Template folders that need to be populated before use
	"$($RepositoryPath)\HPIA Base"
	"$($RepositoryPath)\ADTmaster"

## HPIA_make Packages.ps1
Given model table, create SCCM package(s) of downloaded drivers with 3 programs, collections, and advertisements of each.
Package, program, collection, and advertisement parameters set in #common data section
Activity is logged to file at path in $LogFileSCCM
Customizations required:
	SITE: for ConfigMgr site code (8 times: lines 44, 48, 49, 87, 88, 89, 198, 295)
	\\​server\share for path to server to save downloaded drivers (2 times: line 47, 94)
	DPserver for name of distribution point server (2 times: lines 256, 257)

## HPIA driver pushes.docx
These instructions reiterate some of the same information about creating the packages and programs.  It then describes the process of defining the rings (or phases) of the deployment and creating the actual collections and advertisements for the deployment.  Once started, we would monitor the status of the deployments on a daily basis.  After the deployment was complete, we would gather the machines that failed to run the installation and send it to them a second time as a compliance deployment.  The scripts would be run in order to make deployment collections and advertisements, monitor those advertisements, and follow up on those advertisements.

## HPIA_make_collections&deployments.ps1
Given model table and pre-defined grouping collections, create SCCM deployment collections and advertisements to push drivers
Activity is logged to file at path in $LogFileSCCM
Customizations required:
	SITE: for ConfigMgr site code (3 times: lines 47, 51, 52)
	\\​server\share for path to server to save downloaded drivers (2 times: lines 50, 72)
	For each deployment run, modify lines 62-68 as appropriate

## HPIA_deployment_status_summary.ps1
Given model table and deployment keyword, find deployment status and summarize it.
Activity is logged to file at path in $LogFileSCCM
Output is in c:\temp\deployment_summary.txt and screen
Customizations required:
	SITE: for ConfigMgr site code (1 time: line 42)
	\\​server\share for path to server to save downloaded drivers (1 times: line 50)
	For each deployment run, modify line 45 ($keywords) as appropriate


## HPIA_deployment_status_build_compliance.ps1
Given model table and deployment keyword, find incomplete machines and populate compliance collection.
Activity is logged to file at path in $LogFileSCCM
Customizations required:
	SITE: for ConfigMgr site code (2 times: lines 41, 50)
	\\​server\share for path to server to save downloaded drivers (1 times: line 63)
	For each deployment run, modify line 46 ($keyword) as appropriate


