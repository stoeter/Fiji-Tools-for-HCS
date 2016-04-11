//Macro_Select_ROI_for_Segmentation
macroName = "Macro_Select_ROI_for_Segmentation";
macroShortDescription = "This macro loads images for the user to select ROIs for segmentation.";
macroDescription = "This macro loads images for the user to select ROIs for segmentation." +
	"\nThe macro can handle up to 4 channels, but only one is actually processed" +
	"\nOption to count object manually. The user can manually draw/select an ROI, which is saved to a .zip file." +
	"\nROIs can be loaded and applied on images with another macro." + 
	"\nEach image can be manually annotated/flagged and all data will be stored in a log file.";
macroRelease = "fifth release 07-04-2016 by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;
macroHtml = "<html>"
	+"<font color=red>" + macroName + "\n" + macroRelease + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>" + macroHelpURL + "</font> <br>"
	+"<font color=black>General info:</font> <br>"
	+"<font color=blue>" + generalHelpURL + "</font> <br>"
	+"<font color=black>...get these URLs from Log window!</font> <br>"
   	+"</font>";

//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName,"\nStart:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
print(macroHelpURL);
print(generalHelpURL);

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

availableImageFormats = newArray("Opera (.tif)");  //image formats to choose

Dialog.create("Conditions");
Dialog.addChoice("Image format:", availableImageFormats);
Dialog.addNumber("Channels:", 3);
Dialog.addNumber("Start at well no.", 1);
Dialog.addCheckbox("Show all files in log window?", false);
Dialog.show();
imageFormat = Dialog.getChoice();
numberOfChannels = Dialog.getNumber();
startAtWellNumber = Dialog.getNumber();
fileListToLog = Dialog.getCheckbox();
print("Image format: " + imageFormat + ", channels: " + numberOfChannels + ", start at well no.: " + startAtWellNumber);

//set array variables for RGB merge
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4
availableChannelsTags = newArray("Ch1", "Ch2_subtracted", "Ch3", "Ch4");  //array of color selection for channel 1-4
useChannels =newArray(numberOfChannels);
//channelsTags =newArray(numberOfChannels);
manualCounting = true;
checkControlImage = false;
	
//set variables for auto contrast and background corrections
Dialog.create("Select channels");
Dialog.addMessage("Which channel to use? Give channel specific text!");
Dialog.addString("Channel tag:", availableChannelsTags[1]);
Dialog.show();
channelsTag = Dialog.getString(); 
print("Filter all .tif files for the presence to tag: " + channelsTag);

//list files in directory
fileList = getFileList(inputPath);
l = fileList.length;

k=0;
filteredFileList =newArray(l);

for (i = 0; i < l; i++) {
	if (fileListToLog) print(fileList[i], channelsTag, indexOf(fileList[i],channelsTag));  //this needs to be rewritten with usechannels
	if (indexOf(fileList[i],channelsTag) != -1) {
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

wellList = getAllWellsFuntion(filteredFileList, true);
exampleFileName = getImageFileExample(filteredFileList);

//now load well-field by well-field and merge to RGB
for (currentWell = startAtWellNumber-1; currentWell < wellList.length; currentWell++) { //currentWell < wellList.length; 26-27
	//fileName = wellList[currentWell] + substring(exampleFileName, 6,lengthOf(exampleFileName)); 
	fileName = wellList[currentWell] + substring(exampleFileName, 6,lengthOf(exampleFileName)); 
	IJ.redirectErrorMessages();
	if (imageFormat == "Opera (.tif)") open(inputPath + fileName);
	if (!(nImages > 0)) print("well:", wellList[currentWell], ", file:", fileName, "could not be opened!"); //if no file was found
		else {
		//to log window
		print("well (" + (currentWell + 1) + "/" + (wellList.length) + "):", wellList[currentWell], ", file:", fileName);
		imageTitle = getTitle();
		heightPixel = getHeight();
		widthPixel = getWidth();
		run("Enhance Contrast", "saturated=0.35");
		redoWell = false;
		Dialog.create("Analyse image?");
		Dialog.addCheckbox("Analyse image?", true);
		Dialog.addCheckbox("Do manual counting?", manualCounting);
		Dialog.addCheckbox("End script session?", false);
		Dialog.show();
		analyseWell = Dialog.getCheckbox();
		manualCounting = Dialog.getCheckbox();
		endScriptSession = Dialog.getCheckbox();
		if (analyseWell && !endScriptSession) {
			run("Select None");
			//reset ROImanager
			if (isOpen("ROI Manager")) {
			     selectWindow("ROI Manager");
			     run("Close");
			     }
			if (manualCounting) {	//select manual points 
				setTool("multipoint");
				waitForUser("Select all objects manually then click 'OK'. zoom = [+/-]");	
				run("Measure");
				newImage(substring(fileName, 0, lengthOf(fileName)-4) + "_points", "8-bit white", widthPixel, heightPixel, 1);
				run("Restore Selection");
				run("Draw");
				run("Invert");
				run("Select None");
				saveAs("Results", outputPath + substring(fileName, 0, lengthOf(fileName)-4) + "_manualHSCcount.txt");
				print("manual counting: ", substring(fileName, 0, lengthOf(fileName)-4) + "_manualHSCcount.txt");
				selectWindow(imageTitle);
				}
			//users sets selection and image ia analysed within ROI
			setTool("polygon");
			run("Select None");
			waitForUser("Select region (ROI) to be analyzed then click 'OK'. zoom = [+/-]");
			run("Add to Manager");
			lastROI = roiManager("count")-1;
			if (lastROI == -1) {  //if no ROI was selected ask if user want to jump back to same well again
				Dialog.create("No ROI selected!");
				Dialog.addCheckbox("Select ROI again?", true);
				Dialog.show();
				redoWell = Dialog.getCheckbox();
				} else {      //otherwise save ROIs
				roiManager("select", lastROI);
				roiManager("rename", "ROI_" + call("ij.plugin.frame.RoiManager.getName", lastROI));
				roiManager("save", outputPath + substring(fileName, 0, lengthOf(fileName)-4)  + "_ROIset.zip");
				print("ROI file: ", substring(fileName, 0, lengthOf(fileName)-4)  + "_ROIset.zip");
				}
			if (!redoWell) {
				Dialog.create("Annotate image?");
				Dialog.addCheckbox("Fish is dead?", false);
				Dialog.addCheckbox("Well need re-imaging?", false);
				Dialog.addString("General flag?", "");
				Dialog.show();
				deadFish = Dialog.getCheckbox();
				reImaging = Dialog.getCheckbox();
				generalFlag = Dialog.getString();
				if ((deadFish) || (reImaging) || (generalFlag !="")) {
					print("Annotation well::", wellList[currentWell], "::file::", fileName, "::dead::", deadFish, "::re-imaging::",reImaging, "::flag::",generalFlag);
					}
				} else {
				currentWell--; //go back to same well in next iteration
				}	
			}
		close();
		if (endScriptSession) {
			currentWell = wellList.length;  //end well loop to abort script loop
			print("User ended script.");
			}
		selectWindow("Log"); //save temp log to keep annotations
		saveAs("Text", outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
		}
	}
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");
File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");

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
		if (wellIndex == 0) print("No " + imageFormat + " files found.");
			else wellImageCountList[wellIndex-1] = d2s(wellImageCount,0);                    //write how many imges are in last well
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
