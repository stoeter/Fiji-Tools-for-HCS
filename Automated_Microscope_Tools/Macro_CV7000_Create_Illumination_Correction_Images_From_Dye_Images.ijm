//CV7000_Create_Illumination_Correction
//From_Dye_Images
macroName = "CV7000_Create_Illumination_Correction_From_Dye_Images";
macroShortDescription = "This macro creates images for illumination correction from CV7000 dye measurement.";
macroDescription = "This macro reads CV7000 images of a dye measurement." +
	"<br>Images from all channels are read and images with low intensity will be skipped." +
	"<br>All images of a channel are combined and displayed as a stack to check illumination quality." +
	"<br>The remaining images are blurred and used to create an illumination corection image file for the CV7000." +
	"<br>This correction files can be used with macro CV7000_Illumination_Correction.";
macroRelease = "third release 11-10-2016 by Martin Stoeter (stoeter(at)mpi-cbg.de)";
macroHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki/Macro-" + macroName;
macroHtml = "<html>" 
	+"<font color=red>" + macroName + "\n" + macroRelease + "</font> <br> <br>"
	+"<font color=black>" + macroDescription + "</font> <br> <br>"
	+"<font color=black>Check for more help on this web page:</font> <br>"
	+"<font color=blue>" + macroHelpURL + "</font> <br>"
	+"<font color=black>...get this URL from Log window!</font>"
    +"</font>";
   	
//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName,"\nStart:",year+"-"+month+"	-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
print(macroHelpURL);

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools-for-HCS by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set array variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("back","B03","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("exclude", "include", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
//setDialogImageFileFilter();
print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
//fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings

//check if image are already corrected
print("Number of corrected images...");
filterStrings = newArray("back_","","");
filterTerms = newArray("include", "no filtering", "no filtering"); 
fileListBack = getFilteredFileList(fileList, false, false);
if(fileListBack.length > 0) {
	print("ERROR: found already corrected image!");
	Dialog.create("ERROR: corrected images found!");
	Dialog.addMessage("It looks like this measurement is already corrected by CV7000!?\n \nClick 'OK' and check the selected folder! Macro will exit now...");     
Dialog.addHelp(macroHtml);
Dialog.show;
}

//find all images for camera background subtraction
print("Number of CV7000 dark field correction images...");
filterStrings = newArray("DC_sCMOS","","");
filterTerms = newArray("include", "no filtering", "no filtering");  
fileListCamBkg = getFilteredFileList(fileList, false, false);

//find all images for CV7000 illumination correction, for the purose to assigning channels to wavelength 
print("Number of CV7000 illumination correction images...");
filterStrings = newArray("SC_BP","","");
filterTerms = newArray("include", "no filtering", "no filtering"); 
fileListIllumCV7000 = getFilteredFileList(fileList, false, false); 

//find all images used to calculate illumination correction
print("Number of measurement images...");
filterStrings = newArray("_T00","","");
filterTerms = newArray("include", "no filtering", "no filtering"); 
fileListDyeImages = getFilteredFileList(fileList, false, false);

//get the unique values for well, fields and channel
wellList = getUniqueWellListCV7000(fileListDyeImages, displayFileList);
fieldList = getUniqueFieldListCV7000(fileListDyeImages, displayFileList);
channelList = getUniqueChannelListCV7000(fileListDyeImages, displayFileList);
print("===== starting processing.... =====");

//define the user interface for specifying the calculation of the correction image..
batchMode = false;
availableProjectionType = newArray("Median", "Average", "Max"); 
projectionType = "Median";
bkgNoise = 101;
gaussianBlur = 5;
medianThreshold = 200;
useCV7000fileName = true;
availableIllumCorrImageNames = newArray("CV7000 file name in measurement folder", "CV7000 file name in Condition folder", "File name with channel");
Dialog.create("Settings...");
Dialog.addMessage("Specify how the illumination correction image will be calculated.\nTry first with default values...");     
Dialog.addChoice("Type of z-projection for aggregation:",availableProjectionType, projectionType);
Dialog.addNumber("Subtract fixed values as dark field image (0 = no subtraction):", bkgNoise);
Dialog.addNumber("Apply smoothing on illumination correction image (0 = none):", gaussianBlur);
Dialog.addNumber("Filter images with low intensity (= no/wrong dye images):", medianThreshold);
Dialog.addChoice("Illumination file name standard:", availableIllumCorrImageNames);
Dialog.show;
projectionType = Dialog.getChoice();
bkgNoise = Dialog.getNumber();
gaussianBlur = Dialog.getNumber();
medianThreshold = Dialog.getNumber();
illumfileNameStandard = Dialog.getChoice();

print("type of projection:", projectionType,"; background noise:", bkgNoise, "Gaussian blur:", gaussianBlur);
print("image with median intensity of", medianThreshold, "will be skipped...");
print(illumfileNameStandard);

setBatchMode(batchMode);

channelFilterNames = newArray(fileListIllumCV7000.length);
cv7000illumCorrImageNames = newArray(fileListIllumCV7000.length);
for (currentFile = 0; currentFile < fileListIllumCV7000.length; currentFile++) {   // all CV7000 correction files
	filterStrings = newArray("CH0" + (currentFile + 1),"","");
	filterTerms = newArray("include", "no filtering", "no filtering"); 
	fileListIllumCV7000channel = getFilteredFileList(fileListIllumCV7000, false, false);
	channelFilterNames[currentFile] = substring(fileListIllumCV7000channel[0],indexOf(fileListIllumCV7000channel[0],File.separator + "SC_") + 4,indexOf(fileListIllumCV7000channel[0],File.separator + "SC_") + 12);
	print("CH0" + (currentFile + 1), "is channel", channelFilterNames[currentFile]);
	if(illumfileNameStandard == availableIllumCorrImageNames[0]) {  // standard for measurement folder
		cv7000illumCorrImageNames[currentFile] = substring(fileListIllumCV7000channel[0],indexOf(fileListIllumCV7000channel[0],File.separator + "SC_") + 1,lengthOf(fileListIllumCV7000channel[0]));
		print(cv7000illumCorrImageNames[currentFile]);
		}
	if(illumfileNameStandard == availableIllumCorrImageNames[1]) {  // standard for 'Condition' folder
		cv7000illumCorrImageNames[currentFile] = substring(fileListIllumCV7000channel[0],indexOf(fileListIllumCV7000channel[0],File.separator + "SC_") + 4,lengthOf(fileListIllumCV7000channel[0]) - 9 ) + ".tif";
		print(cv7000illumCorrImageNames[currentFile]);
		}
	if(illumfileNameStandard == availableIllumCorrImageNames[2]) print("File name with channel will be used...");		
	}

numberOfDyeImagesPerChannel = (fileListIllumCV7000.length + 1)/(channelList.length + 1);    //calc number of dye images per channel by dividing total number of images by number of channels
print("expected number of images per dye is", numberOfDyeImagesPerChannel);

for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {   // all channels
	print("===== processing channel " + channelList[currentChannel] + " =====");
	//get all files for one channel
	filterStrings = newArray(channelList[currentChannel] + ".tif","","");
	filterTerms = newArray("include", "no filtering", "no filtering"); 
	fileListChannel = getFilteredFileList(fileListDyeImages, false, false);
	medianOfImages = newArray(fileListChannel.length);   //array to store all median values measured in images
	// all files for one channel
	for (currentFile = 0; currentFile < fileListChannel.length; currentFile++) {   
		IJ.redirectErrorMessages();
		//open(fileListChannel[currentFile]);
		run("Bio-Formats", "open=[" + fileListChannel[currentFile] + "] autoscale color_mode=Default view=[Standard ImageJ] stack_order=XYCZT");
		currentImage = getTitle();
		print("opened (" + (currentFile + 1) + "/" + fileListChannel.length + "):", fileListChannel[currentFile]);  //to log window
		run("Measure");
		medianOfImages[currentFile] = getResult("Median");
		// if low intensity, then skip image because it is not a dye image
		if (medianOfImages[currentFile] > medianThreshold) {			
			print("Median is :", medianOfImages[currentFile], " -> could be a dye image...");
			if (nImages == 1) {
				firstImage = currentImage;
				fileName = File.nameWithoutExtension;   //getTitle(); for saving later, name of stack
				} else {  // join current image to stack
				if (nImages > 1) run("Concatenate...", " title=[" + firstImage + "] image1=[" + firstImage + "] image2=[" + currentImage + "] image3=[-- None --]");
				}
			} else {
			print("Median is :", medianOfImages[currentFile], " -> not a dye image, skipped!");	
			close();
			}
		}
	//let the user check the image stack and manual remove images if they are bad, then generate illumination correction image by projection	
	run("Stack Sorter");	
	waitForUser("check all images for illumination profile and remove slices from bad dye images");
	print("images for illumination image:",nSlices);
	run("Gaussian Blur...", "sigma=" + gaussianBlur + " stack");
	if (nSlices > 1) run("Z Project...", "projection=" + projectionType);
	zProjectionImage = getTitle();
	if (projectionType == "Median") {    //make 16-bit image, after median porjection this is 32-bit
		setMinAndMax(0, 65535);
		run("16-bit");
		resetMinAndMax();
		}
	if (bkgNoise > 0) run("Subtract...", "value=" + bkgNoise);
	//normalize images to around 10000 intensity value as maximum illumination 
	getStatistics(area, mean, min, max);
	//run("Divide...", "value=" + (max / 10000));
	run("Multiply...", "value=" + (10000 / max));
	print("maximun intensity is:",max, "-> image is multiplied with", (10000 / max), " to normalize intensity to 10000.");
	setMinAndMax(0, 65535);  //scale back to 16-bit image
	run("16-bit");
	resetMinAndMax();
	run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1.0000000 pixel_height=1.0000000 voxel_depth=1.0000000");
	//save illumination correction image
	if(illumfileNameStandard == availableIllumCorrImageNames[2]) {  // not standard for CV7000 measurement or "Condition' folder
		fileName = "IlluminationCorrection_" + fileName + "_" + channelFilterNames[currentChannel] + ".tif";
		} else {
		fileName = cv7000illumCorrImageNames[currentChannel];
		}
	selectWindow(zProjectionImage);
	//saveAs("Tiff", outputPath + fileName);
	run("OME-TIFF...", "save=" + outputPath + fileName + " compression=Uncompressed");
	print("saved illumination correction image for channel", channelFilterNames[currentChannel] + ":", fileName);
	close();  //saved zProjectionImage
	close(firstImage);
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
	}

for (currentFile = 0; currentFile < fileListCamBkg.length; currentFile++) {   // all camerea noise images
	IJ.redirectErrorMessages();
	open(fileListCamBkg[currentFile]);
	currentImage = getTitle();
	print("opened (" + (currentFile + 1) + "/" + fileListCamBkg.length + "):", fileListCamBkg[currentFile]);  //to log window
	run("Measure");
	print("Median is :",getResult("Median"));
	if (currentFile == 0) {
		firstImage = currentImage;
		fileName = File.nameWithoutExtension;   //getTitle(); for saving later, name of stack
		} else {  // join current image to stack
		if (nImages > 1) run("Concatenate...", " title=[" + firstImage + "] image1=[" + firstImage + "] image2=[" + currentImage + "] image3=[-- None --]");
		}
	}
close(firstImage);
	
//save results
saveAs("Results", outputPath + "ResultsIllumCorrection.txt");
				
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
selectWindow("Log");
if(outputPath != "not available") {
	saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
	if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	
	}
/////////////////////////////////////////////////////////////////////////////////////////////
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////

//function opens a dialog to set text list for filtering a list
//example: setDialogImageFileFilter();
//this function set interactively the global variables used by the function getFilteredFileList
//this function needs global variables! (see below)
/*
var fileExtension = ".tif";                                                  //default definition of extension
var filterStrings = newArray("","","");                                      //default definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray(filterStrings.length); for  (i = 0; i < filterStrings.length; i++) {filterTerms[i] = "no filtering";} //default definition of filter types (automatic)
//var filterTerms = newArray("no filtering", "no filtering", "no filtering");  //default definition of filter types (manual)
var displayFileList = false;                                                 //shall array window be shown? 
*/
function setDialogImageFileFilter() {
Dialog.create("Image file filter...");  //enable use inveractivity
Dialog.addMessage("Define the files to be processed:");
Dialog.addString("Files should have this extension:", fileExtension);	//add extension
Dialog.addMessage("Define filter for files:");
for (i = 0; i < filterStrings.length; i++) {
	Dialog.addString((i + 1) + ") Filter this text from file list: ", filterStrings[i]);	
	Dialog.addChoice((i + 1) + ") Files with text are included/excluded?", availableFilterTerms, filterTerms[i]);	
	}
Dialog.addCheckbox("Check file lists?", displayFileList);	//if check file lists will be displayed
Dialog.show();
fileExtension = Dialog.getString();
for (i = 0; i < filterStrings.length; i++) {
	filterStrings[i] = Dialog.getString();	
	filterTerms[i] = Dialog.getChoice();	
	}
displayFileList = Dialog.getCheckbox();
}

//function filters a file list for a certain strings
//example: myFileList = getFilteredFileList(myFileList, false, true);
//if filterOnInputList = true, then additional filtering is possible (e.g. file names containing "H08" and "D04" => H08 and D04 in list)
//if filterOnInputList = false, then subsequent filtering is possible (e.g. file names containing "controls" and "positive" => positive controls, but not negative controls in list!)
//this function needs global variables (see function setDialogImageFileFilter)
//var filterStrings = newArray("","","");                                      //pre-definition of strings to filter
//var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
//var filterTerms = newArray("no filtering", "no filtering", "no filtering");
function getFilteredFileList(fileListFunction, filterOnInputList, displayList) {
skippedFilter = 0;	
for (i = 0; i < filterStrings.length; i++) {
	if (filterTerms[i] != availableFilterTerms[0]) {
		returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
		for (j = 0; j < fileListFunction.length; j++) {
			if (filterTerms[i] == "include" && indexOf(fileListFunction[j],filterStrings[i]) != -1) returnedFileList = Array.concat(returnedFileList,fileListFunction[j]);
			if (filterTerms[i] == "exclude" && indexOf(fileListFunction[j],filterStrings[i]) <= 0) returnedFileList = Array.concat(returnedFileList,fileListFunction[j]);
			}
		print(returnedFileList.length + " file(s) found after filter: " + filterTerms[i] + " text " + filterStrings[i] + "."); 
		if (displayList) {Array.show("List of files - after filtering for " + filterStrings[i], returnedFileList);}
		//see description above! default: filterOnInputList = false
		if(!filterOnInputList) fileListFunction = returnedFileList; 
		} else skippedFilter++;
	} 
if (skippedFilter == filterStrings.length) returnedFileList = fileListFunction;	//if no filter condition is selected
return returnedFileList;
}

//function gets all files from folders and subfolders
//example: myFileList = getFileListSubfolder("/home/myFolder/", true);
function getFileListSubfolder(inputPathFunction, displayList) {
fileListFunction = getFileList(inputPathFunction);  //read file list
Array.sort(fileListFunction);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileListFunction.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileListFunction[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPathFunction + fileListFunction[i], displayList);
		returnedFileList = Array.concat(returnedFileList, returnedFileListTemp);
		} else {  									//if it is a file
		returnedFileList = Array.concat(returnedFileList, inputPathFunction + fileListFunction[i]);
		//print(i, inputPath + fileList[i]); //to log window
		}
	}
if(inputPathFunction == inputPath) { //if local variable is equal to global path variable = if path is folder and NOT subfolder
	print(returnedFileList.length + " file(s) found in selected folder and subfolders."); 	
	if (displayList) {Array.show("All files - all",returnedFileList);} 	
	}
return returnedFileList;
}

//function filters all files with certain extension
//example: myFileList = getFileType(myFileList, ".tif", true);
function getFileType(fileListFunction, fileExtension, displayList) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
if(lengthOf(fileExtension) > 0) {
	for (i = 0; i < fileListFunction.length; i++) {
		if (endsWith(fileListFunction[i],fileExtension)) returnedFileList = Array.concat(returnedFileList,fileListFunction[i]);
		}
	print(returnedFileList.length + " file(s) found with extension " + fileExtension + ".");
	if (displayList) {Array.show("All files - filtered for " + fileExtension, returnedFileList);} 
	} else {
	returnedFileList = fileListFunction;	
	}
return returnedFileList;
}

//function filters a list for a certain string (filter)
//example: myList = getFilteredList(myList, "myText", true);
function getFilteredList(inputList, filterStringFunction, displayList {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " file(s) found after filtering: " + filterStringFunction); 
if (displayList) {Array.show("List after filtering for " + filterStringFunction, returnedFileList);}
return returnedList;
}

//function returnes the unique wells of an array of CV7000 files
//example: myUniqueWells = getUniqueWellListCV7000(myList, true);
function getUniqueWellListCV7000(inputArray, displayList) {
currentWell = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00"));   //first well found
returnedWellList = newArray(currentWell);     //this list stores all unique wells found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned well list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedWellList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentWell = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00"));
		if(returnedWellList[j] == currentWell) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedWellList = Array.concat(returnedWellList, currentWell);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellList.length + " wells found."); 
Array.sort(returnedWellList);
if (displayList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}

//function returnes the unique well files (all fields of all wells, e.g. G10_T0001F001) of an array of CV7000 files
//example: myUniqueWellFileds = getUniqueWellFieldListCV7000(myList, true);
function getUniqueWellFieldListCV7000(inputArray, displayList) {
currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00")+10);   //first well field found
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
//print("start:", currentWellField, returnedWellFieldList.length);
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00")+10);
		//print(i,j,currentWellField, returnedWellFieldList[j]);
		if(returnedWellFieldList[j] == currentWellField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	//print("final:", currentWellField, valueUnique, returnedWellFieldList.length);
	if (valueUnique) returnedWellFieldList = Array.concat(returnedWellFieldList, currentWellField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellFieldList.length + " wells fields found."); 
Array.sort(returnedWellFieldList);
if (displayList) {Array.show("List of " + returnedWellFieldList.length + " unique well fields", returnedWellFieldList);}	
return returnedWellFieldList;
}

//function returnes the unique fields (all fields of all wells, e.g. F001, F002,...) of an array of CV7000 files
//example: myUniqueFields = getUniqueFieldListCV7000(myList, true);
function getUniqueFieldListCV7000(inputArray, displayList) {
currentField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+6,lastIndexOf(inputArray[0],"_T00")+10);   //first field found
returnedFieldList = newArray(currentField);     //this list stores all unique fields found and is returned at the end of the function
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentField = substring(inputArray[i], lastIndexOf(inputArray[i],"_T00")+6, lastIndexOf(inputArray[i],"_T00")+10);
		if(returnedFieldList[j] == currentField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedFieldList = Array.concat(returnedFieldList, currentField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedFieldList.length + " field(s) found."); 
Array.sort(returnedFieldList);
if (displayList) {Array.show("List of " + returnedFieldList.length + " unique fields", returnedFieldList);}	
return returnedFieldList;
}

//function returnes the unique channels (e.g. C01) of an array of CV7000 files
//example: myUniqueChannels = getUniqueChannelListCV7000(myList, true);
function getUniqueChannelListCV7000(inputArray, displayList) {
currentChannel = substring(inputArray[0],lastIndexOf(inputArray[0],".tif")-3,lastIndexOf(inputArray[0],".tif"));   //first channel found
returnedChannelList = newArray(currentChannel);     //this list stores all unique channels found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned channel list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedChannelList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentChannel = substring(inputArray[i],lastIndexOf(inputArray[i],".tif")-3,lastIndexOf(inputArray[i],".tif"));
		if(returnedChannelList[j] == currentChannel) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedChannelList = Array.concat(returnedChannelList, currentChannel);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedChannelList.length + " channel(s) found."); 
Array.sort(returnedChannelList);
if (displayList) {Array.show("List of " + returnedChannelList.length + " unique channels", returnedChannelList);}	
return returnedChannelList;
}

//function saves the log window in the given path
//example: saveLog("C:\\Temp\\Log_temp.txt");
function saveLog(logPath) {
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
saveAs("Text", logPath);
if (nImages > 0) selectWindow(currentWindow);
}

//function returns a number in specific string format, e.g 2.5 => 02.500
//example: myStringNumber = getNumberToString(2.5, 3, 6);
function getNumberToString(number, decimalPlaces, lengthNumberString) {
numberString = "000000000000" + toString(number, decimalPlaces);  //convert to number to string and add zeros in the front
numberString = substring(numberString, lengthOf(numberString) - lengthNumberString, lengthOf(numberString)); //shorten string to lengthNumberString
return numberString;
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////












