//Macro_Opera_RGB_merger
macroName = "Opera_RGB_merger";
macroShortDescription = "This macro creates RGB images from Opera microscope .flex images (16-bit).";
macroDescription = "This macro merges up to 4 channels to RBG images from Opera automated microscope." +
	"\nOptionally background substraction and auto-contrast can be adjusted for each channel" +
	"\nand in the manual mode the macro allows interactively to process each image manually.";
macroRelease = "third release 26-06-2014 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//set array variables for RGB merge
availableRGBcolors = newArray("Red", "Green", "Blue", "Grays"); //possible color selections in pull-down
colorsForRGBmerge = newArray("*None*", "*None*", "*None*", "*None*");  //array of color selection for channel 1-4
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4
changeColor = false;
channelColorVector = newArray(4);
channelsForRGBmerge = newArray(4);
availableRGBfileFormats = newArray("jpeg","png"); //possible output RGB file formats

//choose colors for each channel 
Dialog.create("RGB merging");
Dialog.addNumber("Number of fields per well for RGB (0=all):", 0);  //set number of field for RBG images
Dialog.addNumber("Start at well index (first well = 0):", 0);
Dialog.addCheckbox("Do background substraction?", false);
Dialog.addString("Add prefix to all RGB image names:", "");
Dialog.addString("Add suffix to all RGB image names:", "_RGB");
Dialog.addCheckbox("Use barcode and Meas for RGB image name?", false);
Dialog.addChoice("Save RGB images :", availableRGBfileFormats);
Dialog.addCheckbox("Show all files in log window?", false);
Dialog.show();
numberOfSelectedChannels = 0;
numberOfFields = Dialog.getNumber();
startWellIndex = Dialog.getNumber();
bkgCorrection =  Dialog.getCheckbox();
rgbFilePrefix = Dialog.getString();
rgbFileSuffix = Dialog.getString();
useBarcodeMeasTag = Dialog.getCheckbox();
rgbFileFormat = Dialog.getChoice();
fileListToLog = Dialog.getCheckbox();

if (useBarcodeMeasTag) {
	if (endsWith(inputPath,"/")) {
		folderSlash = "/"; //MAC
		} else {
		folderSlash = "\\";//Win
		}
	inputPath = substring(inputPath,0,lengthOf(inputPath)-1);  // remove last character
	barcodeMeasTag = substring(inputPath,lastIndexOf(substring(inputPath,0,lastIndexOf(inputPath,folderSlash)),folderSlash)+1,lengthOf(inputPath));
	barcodeMeasTag = replace(replace(replace(barcodeMeasTag,folderSlash,"_"),")","_"),"(","_");
	outputPath = outputPath + barcodeMeasTag;  //print(outputPath);
	inputPath = inputPath + folderSlash;  // add last character
	}
	
manualMode = true;
seriesString = "";
for (i = 1; i <= numberOfFields; i++) seriesString = seriesString + " series_" + i;   // " series_1 series_2 series_3 series_4"
saveRGB = false;
makeMontage = false;
saveMontage = false;
montageScale = 0.5;

//set variables for auto contrast and background corrections
autoContrastValue = newArray(0.35, 0.35, 0.35, 0.35);
autoContrast = false; 
bkgValue = newArray(200, 200, 200, 200); 
if (bkgCorrection) {
	Dialog.create("Background substraction parameter (0 = not applied)");
	Dialog.addMessage("Background substraction\nRolling ball radius (0 = not applied)");
	for (i = 1; i <= 4; i++) Dialog.addNumber(availableChannels[i], bkgValue[i-1]);
	Dialog.show();
	for (i = 0; i < 4; i++) bkgValue[i] = Dialog.getNumber();
	}
	
//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
run("Color Balance...");

//////////////////             M A C R O   :   R G B - M E R G E   A R R A Y S C A N   I M A G E S       /////////////////////////////// 
//get file list and well list
fileList = getFileList(inputPath);
Array.sort(fileList); //also done in function getAllWellsFunction
l = fileList.length;

if (fileListToLog) for (i = 0; i < l; i++) {
	print(fileList[i]);
	}
wellList = getAllWellsArrayScanFunction(fileList, false, fileListToLog);
exampleFileName = getImageFileExampleArrayScanFunction(fileList);

//now load well-field by well-field and merge to RGB
for (currentWell = startWellIndex; currentWell < wellList.length; currentWell++) {
	showProgress(currentWell, wellList.length);
	fileName = substring(exampleFileName,0,lengthOf(exampleFileName)-14) + wellList[currentWell] 
			+ substring(exampleFileName,lengthOf(exampleFileName)-8,lengthOf(exampleFileName)); 
	//to log window
	//print("well:", wellList[currentWell], ", field:", currentField, ", channel:", currentChannel, " file:", fileName);
	print("well:", wellList[currentWell], ", file:", fileName);
	//if (imageFormat == "Opera (.flex)") run("TIFF Virtual Stack...", "open=" + inputPath + fileName);                           
	if (File.exists(inputPath + fileName)) {
		IJ.redirectErrorMessages();
		if (bkgCorrection) setBatchMode(true);
		if (seriesString == "") {// white spaces dont work!!!
			run("Bio-Formats", "open=" + inputPath + fileName + " autoscale color_mode=Composite concatenate_series open_files open_all_series view=Hyperstack stack_order=XYCZT");
			} else {
			run("Bio-Formats", "open=" + inputPath + fileName + " autoscale color_mode=Composite concatenate_series open_files view=Hyperstack stack_order=XYCZT" + seriesString);				
			}
		imageTitle = getTitle();
		getDimensions(width, height, channels, slices, frames);
		print(width, height, channels, slices, frames);
		fileTitle = getTitle();  //print(fileTitle);
		if (bkgCorrection) {
			labelArray = newArray(frames * channels);
			for (i = 1; i <= frames * channels; i++) {
				setSlice(i);
				labelArray[i-1] = getMetadata("Label");	//print(i,labelArray[i-1]);
				}
			run("Split Channels");
			mergeString = "";
			for (currentChannel = 1; currentChannel <= channels; currentChannel++) {
				selectWindow("C" + currentChannel + "-" + fileTitle);
				if (bkgValue[currentChannel] > 0) run("Subtract Background...", "rolling=" + bkgValue[currentChannel]);
				mergeString = mergeString + "c" + currentChannel + "=[C" + currentChannel + "-" + fileTitle + "] ";
				}
			//run("Merge Channels...", "c1=[C1-002002000.flex - Well B-2; Field #1] c2=[C2-002002000.flex - Well B-2; Field #1] c3=[C3-002002000.flex - Well B-2; Field #1] create");
			run("Merge Channels...", mergeString + "create");
			for (i = 1; i <= frames * channels; i++) {
				setSlice(i);
				setMetadata("Label",labelArray[i-1]);
				}
			setBatchMode(false);	
			}
		//if (autoContrast && autoContrastValue[currentChannel] > 0) run("Enhance Contrast", "saturated=" + autoContrastValue[currentChannel]);
		goToNextWell = false;
		sliceCounter = 1;
		do {
			if (sliceCounter < channels * frames) setSlice(sliceCounter);
			if (manualMode && !goToNextWell) {
				waitForUser("Adjust contrast manually, then 'OK'");
				Dialog.create("Manual mode! Well: " + wellList[currentWell]);  //enable use inveractivity
				Dialog.addCheckbox("Stay in manual mode?", manualMode);
				Dialog.addCheckbox("Make Montage?", makeMontage);
				Dialog.addCheckbox("Save Montage?", saveMontage);
				Dialog.addNumber("Montage scale? (0=dont save)", montageScale);
				Dialog.addString("Add prefix to all RGB image names:", rgbFilePrefix);
				Dialog.addString("Add suffix to all RGB image names:", rgbFileSuffix);
				Dialog.addCheckbox("Save current RGB image", saveRGB);
				Dialog.addNumber("Save number of fields automatically as RGB (-1= none,0=all):", -1);
				Dialog.addCheckbox("Change auto-contrast values?", false);
				Dialog.addCheckbox("Change color of channels?", false);
				Dialog.addCheckbox("Go to next field?", false);
				Dialog.addCheckbox("Go to next well?", false);
				Dialog.show();
				manualMode = Dialog.getCheckbox();
				makeMontage = Dialog.getCheckbox();
				saveMontage = Dialog.getCheckbox();
				montageScale = Dialog.getNumber();
				rgbFilePrefix = Dialog.getString();
				rgbFileSuffix = Dialog.getString();
				saveRGB = Dialog.getCheckbox();
				numberOfFieldsToBeSavedAsRGB = Dialog.getNumber();
				changeAutoContrastDialog = Dialog.getCheckbox();
				changeColorDialog = Dialog.getCheckbox();
				goToNextField = Dialog.getCheckbox();
				goToNextWell = Dialog.getCheckbox();
				} else {
				goToNextWell = true;	// for automaten mode (manual mode == false)
				}
			sliceLabel = getInfo("slice.label");
			//set auto-contrast values
			if (changeAutoContrastDialog) {
				Dialog.create("Set auto-contrast (0 = not applied)");
				Dialog.addMessage("Set auto-contrast\nEnhance contast value (0-1, 0 = not applied)");
				for (i = 1; i <= channels; i++) Dialog.addNumber(availableChannels[i], autoContrastValue[i-1]);
				Dialog.addCheckbox("Apply auto-contrast values?", autoContrast);
				Dialog.show();
				for (i = 0; i < channels; i++) autoContrastValue[i] = Dialog.getNumber();
				autoContrast =  Dialog.getCheckbox();
				changeAutoContrastDialog = false;
				}
			//assign different color to channels	
			if (changeColorDialog) {
				Dialog.create("Specifiy colors");
				Dialog.addMessage("Assign colors to channels");
				for (i = 1; i <= channels; i++) Dialog.addChoice(availableChannels[i+1], availableRGBcolors, availableRGBcolors[i-1]);
				Dialog.show();
				for (i = 0; i < channels; i++) channelColorVector[i] = Dialog.getChoice();
				changeColor = true;
				changeColorDialog = false;
				}
			if (changeColor) {
				for (i = 1; i <= channels; i++)	{
					setSlice(i); //set channels 1,2,3...   print(i,channelColorVector[i-1]);
					run(channelColorVector[i-1]);
					print("Color change: channel " + i + " = " + channelColorVector[i-1]);							
					}
				setSlice(sliceCounter);	
				}
			//make montage	
			if (makeMontage) {
				montageColumns = floor(sqrt(frames - 1) + 1);
				montageRows = floor((frames - 1)/montageColumns + 1);		
				run("Make Montage...", "columns=" + montageColumns + " rows=" + montageRows + " scale=" + montageScale + " first=1 last=" + frames + " increment=1 border=0 font=12 label");
				if (autoContrast) {
					for (currentChannel = 1; currentChannel <= channels; currentChannel++) {
						setSlice(currentChannel);
						if ((autoContrastValue[currentChannel - 1] > 0) && (autoContrastValue[currentChannel - 1] <= 1)) run("Enhance Contrast", "saturated=" + autoContrastValue[currentChannel - 1]);
						}
					}
				fileNameMontage = rgbFilePrefix + substring(fileName,0,lengthOf(fileName)-5) + substring(sliceLabel,7,indexOf(sliceLabel,";")) + "_montage" + rgbFileSuffix + "." + rgbFileFormat;
				rename(fileNameMontage);
				if (saveMontage) {
					saveAs(rgbFileFormat, outputPath + fileNameMontage);
					print("Saved file:", fileNameMontage);						
					}
				if (manualMode) waitForUser("This is the well montage -> 'OK'");
				if (isOpen(fileNameMontage)) close(fileNameMontage);
				}
			//save individual fields as RGB		
			if (saveRGB) {
				fileNameRGB = rgbFilePrefix + substring(fileName,0,lengthOf(fileName)-5) + substring(sliceLabel,7,lengthOf(sliceLabel)) + rgbFileSuffix + "." + rgbFileFormat; 
				saveAs(rgbFileFormat, outputPath + fileNameRGB);
				print("Saved file:", fileNameRGB);
				rename(imageTitle);
				}
			if (goToNextField || !manualMode) sliceCounter = sliceCounter + channels;   //go to next field
			if (makeMontage && !manualMode && !saveRGB) goToNextWell = true;   //go to next well if only montage should be saved in automatic mode	
			if ((sliceCounter > frames) && !manualMode) goToNextWell = true;   //go to next well if all RGB fields are saved and in automatic mode	
			} while (!goToNextWell);	
		if (isOpen(imageTitle)) close(imageTitle);	
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
	if (endsWith(fileList[currentFile],".flex")){ //exclude metadata files
		if (wellIndex == -1) {  //for first image found set first well
			wellIndex++;   //= go to first well
			wellList[wellIndex] = substring(fileList[currentFile],lengthOf(fileList[currentFile])-14,lengthOf(fileList[currentFile])-8);   //= write first well to list	
			} else {
			if (wellList[wellIndex] != substring(fileList[currentFile],lengthOf(fileList[currentFile])-14,lengthOf(fileList[currentFile])-8)) {  //if new well
				wellImageCountList[wellIndex] = wellImageCount;  //= write number of fields into wellCountList
				wellImageCount = 0;   //= reset field count in well 
				wellIndex++;   //= go to next well
				wellList[wellIndex] = substring(fileList[currentFile],lengthOf(fileList[currentFile])-14,lengthOf(fileList[currentFile])-8);   //= write next well to list
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
	if (endsWith(fileList[currentFile],".flex")){ //exclude metadata files
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
