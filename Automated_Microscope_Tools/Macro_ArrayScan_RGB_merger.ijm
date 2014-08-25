//Macro_ArrayScan_RGB_merger
macroName = "ArrayScan_RGB_merger";
macroShortDescription = "This macro creates RGB images from ArrayScan microscope exported .tif images (16-bit).";
macroDescription = "This macro merges up to 4 channels to RBG images exported from ArrayScan automated microscope." +
	"\nOptionally background substraction and auto-contrast can be adjusted for each channel" +
	"\nand in the manual mode the macro allows interactively to process each image manually.";
macroRelease = "second release 04-02-2014 by Martin Stöter (stoeter(at)mpi-cbg.de)";
macroHelpURL = "http://idisk-srv1.mpi-cbg.de/knime/FijiUpdate/TDS%20macros/" + macroName + ".htm";
macroHtml = "<html>" 
	+"<font color=red>" + macroName + "/n" + macroRelease + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>" + macroHelpURL + "</font> <br>"
	+"<font color=black>...get this URL from Log window!</font> <br>"
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

//choose folders
Dialog.show;
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//set array variables for RGB merge
availableRGBcolors = newArray("*None*","red", "green", "blue", "grey"); //possible color selections in pull-down
colorsForRGBmerge = newArray("*None*", "*None*", "*None*", "*None*");  //array of color selection for channel 1-4
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4
channelsForRGBmerge =newArray(4);
availableRGBfileFormats = newArray("png","jpeg","tiff"); //possible output RGB file formats

//choose colors for each channel 
Dialog.create("RGB merging");
for (i = 1; i <= 4; i++) Dialog.addChoice(availableRGBcolors[i], availableChannels);
Dialog.addNumber("Number of fields per well for RGB:", 1);  //set number of field for RBG images
Dialog.addNumber("Start at well index (first well = 0):", 0);
Dialog.addCheckbox("Apply \"Window -> Tile\"?", true);
Dialog.addCheckbox("Adjust image contrast manually?", false);
Dialog.addCheckbox("Set auto-contrast values?", false);
Dialog.addCheckbox("Do background substraction?", false);
Dialog.addCheckbox("Set batch mode (no images shown)?", false);
Dialog.addString("Add prefix to all RGB image names:", "");
Dialog.addString("Add suffix to all RGB image names:", "_RGB");
Dialog.addChoice("Save RGB images :", availableRGBfileFormats);
Dialog.addCheckbox("Show all files in log window?", false);
Dialog.show();
numberOfSelectedChannels = 0;
for (i = 0; i < 4; i++) {
	channelsForRGBmerge[i] = Dialog.getChoice();
	if (channelsForRGBmerge[i] != "*None*") numberOfSelectedChannels++;  //count how many channels are actually selected
	}
numberOfFields = Dialog.getNumber();
startWellIndex = Dialog.getNumber();
tileWindows = Dialog.getCheckbox();
manualMode = Dialog.getCheckbox();
autoContrast = Dialog.getCheckbox();
bkgCorrection =  Dialog.getCheckbox();
batchMode =  Dialog.getCheckbox();
rgbFilePrefix = Dialog.getString();
rgbFileSuffix = Dialog.getString();
rgbFileFormat = Dialog.getChoice();
fileListToLog = Dialog.getCheckbox();
saveRGB = true;

if (manualMode) run("Brightness/Contrast...");

//set variables for auto contrast and background corrections
autoContrastValue = newArray(0.05, 0.05, 0.05, 0.05); 
bkgValue = newArray(100, 100, 100, 100); 
if (autoContrast) {
	Dialog.create("Set auto-contrast (0 = not applied)");
	Dialog.addMessage("Set auto-contrast\nEnhance contast value (0-1, 0 = not applied)");
	for (i = 1; i <= 4; i++) Dialog.addNumber(availableChannels[i], autoContrastValue[i-1]);
	Dialog.show();
	for (i = 0; i < 4; i++) autoContrastValue[i] = Dialog.getNumber();
	}
if (bkgCorrection) {
	Dialog.create("Background substraction parameter (0 = not applied)");
	Dialog.addMessage("Background substraction\nRolling ball radius (0 = not applied)");
	for (i = 1; i <= 4; i++) Dialog.addNumber(availableChannels[i], bkgValue[i-1]);
	Dialog.show();
	for (i = 0; i < 4; i++) bkgValue[i] = Dialog.getNumber();
	}
	
//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=75 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
setBatchMode((batchMode && !manualMode));

//////////////////             M A C R O   :   R G B - M E R G E   A R R A Y S C A N   I M A G E S       /////////////////////////////// 
//get file list and well list
fileList = getFileList(inputPath);
Array.sort(fileList); //also done in function getAllWellsFunction
l = fileList.length;

if (fileListToLog) for (i = 0; i < l; i++) {
	print(fileList[i]);
	}
wellList = getAllWellsArrayScanFunction(fileList, true, fileListToLog);
exampleFileName = getImageFileExampleArrayScanFunction(fileList);
//create list field strings for file names
fieldList = newArray(numberOfFields);
for (i = 0; i < numberOfFields; i++) fieldList[i] = "f" + substring("0" + d2s(i,0),lengthOf("0" + d2s(i,0))-2,lengthOf("0" + d2s(i,0)));

//now load well-field by well-field and merge to RGB
for (currentWell = startWellIndex; currentWell < wellList.length; currentWell++) {
	showProgress(currentWell, wellList.length);
	for (currentField = 0; currentField < numberOfFields; currentField++) {
		for (channels = 0; channels < channelsForRGBmerge.length; channels++) {
			if (channelsForRGBmerge[channels] != "*None*") {
				currentChannel = parseInt(substring(channelsForRGBmerge[channels],lengthOf(channelsForRGBmerge[channels])-1,lengthOf(channelsForRGBmerge[channels])));  //get number of selected channel to be opened
				fileName = substring(exampleFileName,0,lengthOf(exampleFileName)-12) + wellList[currentWell] + fieldList[currentField] + "d" + currentChannel 
				+ substring(exampleFileName,lengthOf(exampleFileName)-4,lengthOf(exampleFileName)); 
				//to log window
				print("well:", wellList[currentWell], ", field:", currentField, ", channel:", currentChannel, " file:", fileName);
				IJ.redirectErrorMessages();
				if (File.exists(inputPath + fileName)) {
					open(inputPath + fileName);
					rename("Channel_" + currentChannel);
					if (bkgCorrection && bkgValue[currentChannel] > 0) run("Subtract Background...", "rolling=" + bkgValue[currentChannel]);
					if (autoContrast && autoContrastValue[currentChannel] > 0) run("Enhance Contrast", "saturated=" + autoContrastValue[currentChannel]);
					//waitForUser("stop");   //debugging
					}
				}
			}
		if (manualMode) {
			if (tileWindows) run("Tile");
			waitForUser("Adjust contrast manually, then 'OK'");
			Dialog.create("Manual mode! Well: " + wellList[currentWell]);  //enable use inveractivity
			Dialog.addCheckbox("Stay in manual mode?", manualMode);
			Dialog.addString("Add prefix to all RGB image names:", rgbFilePrefix);
			Dialog.addString("Add suffix to all RGB image names:", rgbFileSuffix);
			Dialog.addCheckbox("Save RGB image", saveRGB);
			Dialog.show();
			manualMode = Dialog.getCheckbox();
			rgbFilePrefix = Dialog.getString();
			rgbFileSuffix = Dialog.getString();
			saveRGB = Dialog.getCheckbox();
			}
		if (nImages == numberOfSelectedChannels) {  // if open image number is not what is expected, then dont save
			run("Merge Channels...", "red=" + channelsForRGBmerge[0] + " green=" + channelsForRGBmerge[1] + " blue=" + channelsForRGBmerge[2] + " gray=" + channelsForRGBmerge[3]);
			rgbImage = getImageID();
			fileNameRGB = rgbFilePrefix + substring(exampleFileName,0,lengthOf(exampleFileName)-12) + wellList[currentWell] + fieldList[currentField] + rgbFileSuffix + "." + rgbFileFormat; 
			if (saveRGB) {
				saveAs(rgbFileFormat, outputPath + fileNameRGB);
				print("Saved file:", fileNameRGB);
				}
			selectImage(rgbImage);
			close();
			} else {
			print("Expected images = " + numberOfSelectedChannels + ", open images = " + nImages + ". Script cannot mergeRGB automatically and save!");	
			waitForUser("Expected images = " + numberOfSelectedChannels + ", open images = " + nImages + ".\n Script cannot mergeRGB and save! Do manually, then press 'OK'");	
			run("Close All");
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
function getAllWellsArrayScanFunction(fileList, closeWindow, fileListToLog) {
//function get all unique wells from a file list
//the file list needs to be a list of files exported from ArrayScan/HCSView (.tif or .TIF)
//the function goes through the sorted list and finds the well-text in file name (MFGTMP_131004100001_C02f00d1.TIF position 12 to 9 counted form end of file name => C02)
//unique well-text and number of found images per well (fields x channels) are put to a list/array
//message pops up information about number of wells found and their number of images, that will be closed then second parameter = true
Array.sort(fileList);
wellList = newArray(fileList.length);
wellImageCountList = newArray(fileList.length);
wellIndex = -1;   //= no entry in wellList (length(wellList)=0)
wellImageCount = 0;
currentFile = 0;
while (currentFile < fileList.length) { //for all files found
	if (endsWith(fileList[currentFile],".tif") || endsWith(fileList[currentFile],".TIF")){ //exclude metadata files
		if (wellIndex == -1) {  //for first image found set first well
			wellIndex++;   //= go to first well
			wellList[wellIndex] = substring(fileList[currentFile],lengthOf(fileList[currentFile])-12,lengthOf(fileList[currentFile])-9);   //= write first well to list	
			} else {
			if (wellList[wellIndex] != substring(fileList[currentFile],lengthOf(fileList[currentFile])-12,lengthOf(fileList[currentFile])-9)) {  //if new well
				wellImageCountList[wellIndex] = wellImageCount;  //= write number of fields into wellCountList
				wellImageCount = 0;   //= reset field count in well 
				wellIndex++;   //= go to next well
				wellList[wellIndex] = substring(fileList[currentFile],lengthOf(fileList[currentFile])-12,lengthOf(fileList[currentFile])-9);   //= write next well to list
				}
			}
			wellImageCount++;				
		}		
	//for debugging: 
	if (fileListToLog) print(fileList[currentFile], currentFile, wellList[wellIndex], wellIndex, wellImageCount);
	currentFile++;
	}
	wellImageCountList[wellIndex] = wellImageCount;  //= write number of fields from last well into wellCountList
	
//trim array lists and show in window
wellList = Array.slice(wellList,0,wellIndex+1);
wellImageCountList = Array.slice(wellImageCountList,0,wellIndex+1);
//show result of well list
Array.show("Wells & images found (indexes)",wellList,wellImageCountList);
waitForUser("Number of well found: " + (wellIndex+1) + "\n " + " \n" +"Check if number of wells and number of images in well" + "\n" + "are as expected! Otherwise press 'ESC' and check image list!");
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
function getImageFileExampleArrayScanFunction(fileList) {
//function get an image file name as an example from a file list
//the file list needs to have image file name with these extensoins: .tif or .TIF
//message pops up if no image is found and macro is aborted
currentFile = 0;
do {
	if (endsWith(fileList[currentFile],".tif") || endsWith(fileList[currentFile],".TIF")){ //exclude metadata files
		//end of function: first image name
		return fileList[currentFile];
		}
	currentFile++;
	} while (currentFile < fileList.length); //for all files found
//show file list and abort macro
Array.show(fileList);
exit("No image files found!?" + "\n " + " \n" +"Check image list!");
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////
