//Macro_Segment2D_in_ROI
macroName = "Macro_Segment2D_in_ROI";
macroShortDescription = "This macro loads images and ROIs (.zip) to do segmetation for pre-processed Opera images (.tif).";
macroDescription = "This macro loads images and ROIs (.zip) to do segmetation for pre-processed Opera images (.tif)." +
	"\nOptionally, new segmentation parameters can be adjusted and measurement can be done in multiple channels" +
	"\nIn the manual mode the macro allows interactively to process each image manually, alternatively batch processing is possible.";
macroRelease = "fifth release 08-04-2016 by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;
macroHtml = "<html>"
	+"<font color=red>" + macroName + "\n" + macroRelease + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>" + macroHelpURL + "</font> <br>"
	+"<font color=black>General info:</font> <br>"
	+"<font color=blue>" + generalHelpURL + "</font> <br>"
	+"<font color=black>...get this URLs from Log window!</font> <br>"
   	+"</font>";

//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName,"\nStart:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
print(macroHelpURL);

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools by TDS@MPI-CBG)\n \n" + macroShortDescription + "\nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
roiPath = getDirectory("Choose ROI folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");

printPaths = "inputPath = \"" + inputPath + "\";\nroiPath = \"" + roiPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

availableImageFormats = newArray("Opera (.tif)");  //image formats to choose

Dialog.create("Conditions");
Dialog.addChoice("Image format:", availableImageFormats);
Dialog.addNumber("Channels:", 3);
Dialog.addNumber("Start at well no.", 1);
Dialog.show();
imageFormat = Dialog.getChoice();
numberOfChannels = Dialog.getNumber();
startAtWellNumber = Dialog.getNumber();

//set array variables for RGB merge
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4
availableChannelsTags = newArray("Ch1", "Ch2_subtracted", "Ch3", "Ch4");  //array of color selection for channel 1-4
useChannels = newArray(numberOfChannels);
channelsTags = newArray(numberOfChannels);
channelFileName = "noOtherChannelImageOpen";
montageImage = "noMontageImageOpen";
ROImaskImage = "noROImaskImageOpen";
segmentationImageROI = "noSegmentationImageROIOpen";

//set boolean variables
analyseWell = true;
manualMode = true;
previousSegmentation = false;
checkControlImage = false;

//set segmentation defaults
availableROIpixelsForSegmentation = newArray("ROI_only", "complete_Image");  //array of possible sets of pixels for segmentation  //, "do_both:_complete_Image_and_ROI_only"
ROIpixelsForSegmentation = availableROIpixelsForSegmentation[0];
gaussianBlurRadius = 1.00;
rollingBallRadius = 15;
unsharpMaskRadius = 5;
maskWeight = 0.4;                  //   0      1         2           3       4      5           6        7           8          9       10       11           12              13        14       15	
allAutoThresholdMethods = newArray("Default","Huang","Intermodes","Isodata","Li","MaxEntropy","Meas","MinError(I)","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhan","Triangle","Yen");
autoThresholdMethod = allAutoThresholdMethods[0];
minObjectSize = 5;
maxObjectSize = 200;
segmentationImage = "segmentation";
	
//set variables for auto contrast and background corrections
Dialog.create("Select channels");
Dialog.addMessage("Which channel to use and give channel specific text?");
for (i = 1; i <= numberOfChannels; i++) Dialog.addCheckbox("Channel " + i, useChannels[i-1]);
for (i = 1; i <= numberOfChannels; i++) Dialog.addString("Channel " + i, availableChannelsTags[i-1]);
Dialog.addCheckbox("Use previous segmentation?", previousSegmentation);	
Dialog.show();
for (i = 0; i < numberOfChannels; i++) useChannels[i] = Dialog.getCheckbox();
for (i = 0; i < numberOfChannels; i++) channelsTags[i] = Dialog.getString();
previousSegmentation = Dialog.getCheckbox();
//to log
print("Segmentation parameters (default): Gaussian radius =",gaussianBlurRadius,"; Unsharp mask radius/weight =",unsharpMaskRadius,"/",maskWeight,"; Auto Threshold Method =",autoThresholdMethod,"\nMinimum object size =",minObjectSize,"; Maximum object size =",maxObjectSize);

//get list of channels
channelTagList = newArray(0);
for (i = 1; i <= numberOfChannels; i++) {
	if (useChannels[i-1]) channelTagList = Array.concat(channelTagList,channelsTags[i-1]);
	}
Array.print(channelTagList);
// select segmentation channel if more than one
if (lengthOf(channelTagList) > 1) {  
	Dialog.create("Which is segmentation channel?");
	Dialog.addChoice("Segmentation on channel:", channelTagList);
	Dialog.show();
	segmentationChannelTag = Dialog.getChoice();
	} else {
	segmentationChannelTag = channelTagList[0];
	}
//resort channel list so that segmentation channel is first in list
tempchannelTagList = newArray(1);
tempchannelTagList[0] = segmentationChannelTag;
for (i = 0; i < lengthOf(channelTagList); i++) {
	if (channelTagList[i] != segmentationChannelTag) tempchannelTagList = Array.concat(tempchannelTagList,channelTagList[i]);
	}
channelTagList = tempchannelTagList;
Array.print(channelTagList);
	
//list files in directory
fileList = getFileList(inputPath);
l = fileList.length;

k=0;
filteredFileList =newArray(l);
for (i = 0; i < l; i++) {
	//print(fileList[i], segmentationChannelTag, indexOf(fileList[i],segmentationChannelTag));
	if (indexOf(fileList[i],segmentationChannelTag) != -1) {
		filteredFileList[k] = fileList[i];
		k++;
		}
	}
	
filteredFileList = Array.slice(filteredFileList,0,k);
//check if files were found
if (filteredFileList.length == 0) {
	print("No files found!", filteredFileList.length);
	exit("No files found!");
	}
	
//setBatchMode(true);
//configure
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Options...", "iterations=1 count=1 black edm=Overwrite");
run("Close All");
setForegroundColor(0, 0, 0);
run("Clear Results");

wellList = getAllWellsFuntion(filteredFileList, false);
print(filteredFileList.length, " wells found.");
exampleFileName = getImageFileExample(filteredFileList);
//create list field strings for file names

//now load well by well
for (currentWell = startAtWellNumber-1; currentWell < wellList.length; currentWell++) { //currentWell < wellList.length; 26-27
	//fileName = wellList[currentWell] + substring(exampleFileName, 6,lengthOf(exampleFileName)); 
	fileName = wellList[currentWell] + substring(exampleFileName, 6,lengthOf(exampleFileName)); 
	IJ.redirectErrorMessages();
	if (imageFormat == "Opera (.tif)") open(inputPath + fileName);
	if (!(nImages > 0)) print("#",currentWell,", well:", wellList[currentWell], ", file:", fileName, "could not be opened!"); //if no file was found
		else {
		//to log window
		print("well (" + (currentWell + 1) + "/" + (wellList.length) + "):", "well:", wellList[currentWell], ", file:", fileName);
		imageTitle = getTitle();
		heightPixel = getHeight();
		widthPixel = getWidth();
		if (manualMode) {
			run("Enhance Contrast", "saturated=0.35");
			Dialog.create("Analyse image?");
			Dialog.addCheckbox("Analyse image?", analyseWell);
			Dialog.addCheckbox("Stay in manual mode?", true);	
			Dialog.addCheckbox("Check final control image?", checkControlImage);
			Dialog.show();
			analyseWell = Dialog.getCheckbox();
			manualMode = Dialog.getCheckbox();
			checkControlImage = Dialog.getCheckbox();
			}
		if (analyseWell) {
			//reset ROImanager and load ROI
			if (isOpen("ROI Manager")) {
			     selectWindow("ROI Manager");
			     run("Close");
			     }
			roiFileName = substring(fileName, 0, lengthOf(fileName)-4)  + "_ROIset.zip";
			if (!File.exists(roiPath + roiFileName)) {
				printText = "ROI-file not found:\n" + roiFileName + "\nnot found in folder: " + roiPath;
				print(printText);
				close(imageTitle);
				} else {			
				run("Select None");
				run("ROI Manager...");
				roiManager("Show None");
				roiManager("Open", roiPath + roiFileName);
				//generate ROI outline image
				newImage("ROI outline", "8-bit white", widthPixel, heightPixel, 1);
				roiManager("Select", 0);
				roiManager("Draw");
				run("Invert");
				if (previousSegmentation) { //use loaded segmentation
					//generate segmentation outline image
					//setBatchMode(true);
					newImage("Segmentation outline", "8-bit white", widthPixel, heightPixel, 1);
					for (i=1; i < roiManager("count"); i++) {
   	   					roiManager("Select", i);
						roiManager("Draw");
						}
					run("Invert");
					} else {  //do new sementation 
					//setBatchMode(true);
					roiCount = roiManager("count");
					for (i=1; i < roiCount; i++) { //deletes ROIs backwards from last until secon ROI, first is kept
						roiManager("Select", roiCount - i);
						roiManager("Delete");
						}
					updateResults();
					setBatchMode(false);
					do {  //do auto threshold montage until dialog unchecked
						if (isOpen(segmentationImage)) close(segmentationImage);
						selectWindow(fileName);
						if (manualMode) {
							Dialog.create("Set segmentation parameters?");	
							Dialog.addChoice("For segmentation use pixels from:", availableROIpixelsForSegmentation, ROIpixelsForSegmentation);
							Dialog.addMessage(" ... in manual mode only one segmentation region!")
							Dialog.addNumber("Gaussian Blur radius:", gaussianBlurRadius);
							Dialog.addNumber("Background subtraction:", rollingBallRadius);
							Dialog.addNumber("Unsharp Mask radius:", unsharpMaskRadius);
							Dialog.addNumber("Unsharp Mask weight:", maskWeight);
							Dialog.addMessage(" ... enter 0 for no blur, no subtraction or no unsharp mask!")	
							Dialog.addChoice("Auto Threshold method?", allAutoThresholdMethods, autoThresholdMethod);
							Dialog.addCheckbox("Show all auto threshold methods?", false);
							Dialog.addNumber("Minimum object size:", minObjectSize);
							Dialog.addNumber("Maximum object size:", maxObjectSize);
							Dialog.show();
							ROIpixelsForSegmentation = Dialog.getChoice();
							gaussianBlurRadius = Dialog.getNumber();
							rollingBallRadius = Dialog.getNumber();
							unsharpMaskRadius = Dialog.getNumber();
							maskWeight = Dialog.getNumber();
							autoThresholdMethod = Dialog.getChoice();
							autoThresholdMontage = Dialog.getCheckbox();
							minObjectSize = Dialog.getNumber();
							maxObjectSize = Dialog.getNumber();
							print("Segmentation parameters: segmentation in" + ROIpixelsForSegmentation + "; Gaussian radius =",gaussianBlurRadius,"; Unsharp mask radius =",unsharpMaskRadius,"/",maskWeight,"; Auto Threshold Method =",autoThresholdMethod,"\nMinumum object size =",minObjectSize,"; Maximum object size =",maxObjectSize);
							}
						run("Duplicate...", "title=" + segmentationImage);
						if (gaussianBlurRadius > 0) run("Gaussian Blur...", "sigma=" + gaussianBlurRadius);
						if (rollingBallRadius > 0) run("Subtract Background...", "rolling=" + rollingBallRadius);					
						if (unsharpMaskRadius > 0) run("Unsharp Mask...", "radius=" + unsharpMaskRadius + " mask=" + maskWeight);
						if (indexOf(ROIpixelsForSegmentation, "ROI_only") >= 0) {
							selectWindow(segmentationImage);
							roiManager("Select", 0);
							run("Restore Selection");
							run("Create Mask");
							ROImaskImage = getTitle();
							run("Divide...", "value=255");
							imageCalculator("Multiply create", segmentationImage, ROImaskImage);
							segmentationImageROI = getTitle();
							}
						if (autoThresholdMontage) {
							run("Auto Threshold", "method=[Try all] ignore_black ignore_white white");	
							montageImage = getTitle();
							waitForUser("'OK' to continue... (back to dialog)");
							}
						if (isOpen(montageImage)) close(montageImage);
						if (isOpen(ROImaskImage)) close(ROImaskImage);
						if (isOpen(segmentationImageROI)) close(segmentationImageROI);
						} while (autoThresholdMontage);
					selectWindow(segmentationImage);
					run("Auto Threshold", "method=" + autoThresholdMethod + " ignore_black ignore_white white");
					run("Watershed");
					roiManager("Select", 0);
					run("Analyze Particles...", "size=" + minObjectSize + "-" + maxObjectSize + " circularity=0.00-1.00 show=[Bare Outlines] include add");
					rename("Segmentation outline");
					run("Invert");
					close(segmentationImage);
					roiManager("save", outputPath + substring(fileName, 0, lengthOf(fileName)-4)  + "_ROIsetNew.zip");
					}
				//now analyse ROI image
				selectWindow(fileName);
				run("Select None");
  				run("Clear Results");
				//setBatchMode(true);
				selectWindow(fileName);
				for (i=0; i < roiManager("count"); i++) {  //measure segmentation channel
      				roiManager("Select", i);
					roiManager("Measure");
					}
				//set contrast for RGB
				run("Select None");
				resetMinAndMax();
				run("Enhance Contrast", "saturated=2");							
				run("8-bit");
				//run("Merge Channels...", "c2=[Segmentation outline] c4=" + fileName + " c5=[ROI outline]");
				run("Merge Channels...", "c1=[Segmentation outline] c2=" + fileName + " c5=[ROI outline]");
				//close("RGB");  //composite
				//selectWindow("RGB (RGB)");
				fileNameRGB = substring(fileName, 0, lengthOf(fileName)-4) + "_manualRGBoutlines" + ".png";	
				saveAs("PNG", outputPath + fileNameRGB);
				print("Saved file:", fileNameRGB);
				//now analyse all other channels
				for (currentChannel = 2; currentChannel <= lengthOf(channelTagList); currentChannel++) {  //if other channels show be quantified as well	
					channelFileName = substring(fileName,0,indexOf(fileName, segmentationChannelTag)) + channelTagList[currentChannel - 1] + substring(exampleFileName, lengthOf(exampleFileName) - 9,lengthOf(exampleFileName)); 
					//to log window
					print("#",currentWell,", well:", wellList[currentWell], ", file:", channelFileName);
					if (File.exists(inputPath + channelFileName)) {
						open(inputPath + channelFileName);	
						for (i=0; i < roiManager("count"); i++) {
   							roiManager("Select", i);
							roiManager("Measure");
							}
						} else {
						printText = "File not found:\n" + channelFileName + "\nnot found in folder: " + inputPath;
						print(printText);
						}
					if (isOpen(channelFileName)) close(channelFileName);
					}   				
				saveAs("Results", outputPath + substring(fileName, 0, lengthOf(fileName)-4) + "_manualROI_HSCcount.txt");
				updateResults();
				setBatchMode(false);
				if (checkControlImage && manualMode) { //check manually segmentation
					selectWindow(fileNameRGB);
					setTool("zoom");
					waitForUser;
					}
				if (isOpen(fileNameRGB)) close(fileNameRGB);
				run("Clear Results");
				}
			} else {
			close(imageTitle);
			}
		selectWindow("Log");  //save temp log
		saveAs("Text", outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
		}
	}	
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 

/////////////////////////////////////////////////////////////////////////////////////////////
////////			F U N C T I O N S				/////////////
/////////////////////////////////////////////////////////////////////////////////////////////
function getAllWellsFuntion(fileList, closeWindow) {
//function get all unique wells from a file list
//the file list needs to be a list of files exported from ArrayScan/HCSView (.tif or .TIF)
//the function goes through the sorted list and finds the well-text in file name (MFGTMP_131004100001_C02f00d1.TIF position 12 to 9 counted form end of file name => C02)
//unique well-text and number of found images per well (fields x channels) are put to a list/array
//message pops up information about number of wells found and their number of images, that will be closed then second parameter = true
Array.sort(fileList);
wellList = newArray(fileList.length);
wellImageCountList = newArray(fileList.length);
wellIndexList = newArray(fileList.length);
wellIndex = 0;
wellImageCount = 0;
currentFile = 0;
if (imageFormat == "Opera (.tif)") { //forward well reading
	do {
		if (endsWith(fileList[currentFile],".tif")){ //exclude metadata files
			wellImageCount++;
			if (wellIndex == 0) {  //for first image found set current well
				currentWell = substring(fileList[currentFile], 0,6);
				wellList[wellIndex] = currentWell;
				wellIndexList[wellIndex] = d2s(wellIndex+1,0);
				wellIndex++;
				}
			//check if next image belongs to same well, if not put well and counted field-channel images in list
			if (currentWell != substring(fileList[currentFile],0,6)) {
				wellImageCountList[wellIndex-1] = d2s(wellImageCount-1,0);   //write how many images in current well
				wellImageCount = 1;                                 //reset counter
				currentWell = substring(fileList[currentFile],0,6);
				wellList[wellIndex] = currentWell;                  //set new current well 
				wellIndexList[wellIndex] = d2s(wellIndex+1,0);
				wellIndex++;			
				}
			//for debugging: print(fileList[currentFile], currentFile, currentWell, wellIndex, wellImageCount); 	
			}
		currentFile++;
		} while (currentFile < fileList.length); //for all files found
		wellImageCountList[wellIndex-1] = d2s(wellImageCount,0);                    //write how many imges are in last well
	}
	
//trim array lists and show in window
wellList = Array.slice(wellList,0,wellIndex);
wellIndexList = Array.slice(wellIndexList,0,wellIndex);
wellImageCountList = Array.slice(wellImageCountList,0,wellIndex);
//show result of well list
Array.show(wellIndexList,wellList,wellImageCountList);
waitForUser("Number of well found: " + wellIndex + "\n " + " \n" +"Check if number of wells and number of images in well" + "\n" + "are as expected! Otherwise press 'ESC' and check image list!");
//tidy up and close windows
if (closeWindow) {
	windowList = getList("window.titles");
	for (i = 0; i < windowList.length; i++) {
		if (windowList[i] == "Arrays") {
			selectWindow("Arrays");
			run("Close");
			}
		}
	}
//end of function: return well list
return wellList;
}
/////////////////////////////////////////////////////////////////////////////////////////////////
function getImageFileExample(fileList) {
//function get an image file name as an example from a file list
//the file list needs to have image file name with these extensoins: .tif or .TIF
//message pops up if no image is found and macro is aborted
currentFile = 0;
if (imageFormat == "Opera (.tif)") {
	do {
		if (endsWith(fileList[currentFile],".tif")){ //exclude metadata files
			//end of function: first image name
			return fileList[currentFile];
			}
		currentFile++;
		} while (currentFile < fileList.length); //for all files found
	}
//show file list and abort macro
Array.show(fileList);
exit("No image files found!?" + "\n " + " \n" +"Check image list!");
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////
