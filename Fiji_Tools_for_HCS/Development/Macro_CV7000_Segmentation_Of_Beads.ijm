//Macro_CV7000_Segmentation_Of_Beads
macroName = "CV7000-Segmentation-Of-Beads";
macroShortDescription = "This macro segments object such as beads and saves object data.";
macroDescription = "This macro segments object such as beads and saves object data." +
	"<br>This macro reads single .tif images from the chosen folder/subfolders," +
	"<br>files can be filtered and segmentation parameters can be adjusted." +
	"<br>Default settings are for 2.5 microns beads";
macroRelease = "second release 30-12-2015 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
var inputPath = "Y:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\141111-BeadStacks-1_20141111_134223_raw\\AssayPlate_PerkinElmer_CellCarrier-384\\";
var outputPath = "Y:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\analysis\\output_20150115\\"; 
//inputPath = getDirectory("Choose image folder... ");
//outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set array variables
batchMode = false;
var fileExtension = ".tif";													//pre-definition of extension
var filterStrings = newArray("sequence","GSP","RVS");				        	//pre-definition of strings to filter
var filterStrings = newArray("CellCarrier","Z11C","");				        	//pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");  //dont change this
var filterTerms = newArray("include", "include", "no filtering");	//pre-definition of filter types 
var displayFileList = true;

//set array variables for RGB merge
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4
availableChannelsTags = newArray("Ch1", "Ch2_substracted", "Ch3", "Ch4");  //array of color selection for channel 1-4
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
gaussianBlurRadius = 1.50;    //CellCarrier 2.5micron beads
rollingBallRadius = 0;   //CellCarrier 2.5micron beads
// postion in array                     0      1         2           3       4      5           6        7           8          9       10       11           12              13        14       15	
allAutoThresholdMethods = newArray("Default","Huang","Intermodes","Isodata","Li","MaxEntropy","Meas","MinError(I)","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhan","Triangle","Yen");
autoThresholdMethod = allAutoThresholdMethods[10]; //CellCarrier 2.5micron beads Otsu
minObjectSize = 400;   //CellCarrier 2.5micron beads
maxObjectSize = 1000;  //CellCarrier 2.5micron beads
minObjectCircularity = 0.50;   //CellCarrier 2.5micron beads
maxObjectCircularity = 1.00;  //CellCarrier 2.5micron beads
segmentationImage = "segmentation";

//set variables for auto contrast and background corrections
print("Default segmentation parameters for 2.5 micro meter beads are:\nGaussian radius =",gaussianBlurRadius,"; Background subtraction =",rollingBallRadius,"; Auto Threshold Method =",autoThresholdMethod,"\nMinimum object size =",minObjectSize,"; Maximum object size =",maxObjectSize,"Minimum object circularity =",minObjectCircularity,"; Maximum object circularity =",maxObjectCircularity,";");
print("Segmentation parameters for 500 nano meter beads should be:\nGaussian radius = 0.80 ; Background subtraction = 0 ; Auto Threshold Method =",allAutoThresholdMethods[15],"\nMinimum object size = 5 ; Maximum object size = 500 ; Minimum object circularity = 0.00 ; Maximum object circularity = 1.00 ;");
Dialog.create("Adjust Segmentation Parameters");
Dialog.addChoice("Auto Threshold method:", allAutoThresholdMethods, autoThresholdMethod);
Dialog.addNumber("Gaussian Blur radius:", gaussianBlurRadius);
Dialog.addNumber("Background subtraction (0 = none):", rollingBallRadius);
Dialog.addNumber("Minumum object size:", minObjectSize);
Dialog.addNumber("Maximum object size:", maxObjectSize);
Dialog.addNumber("Minumum object circularity:", minObjectCircularity);
Dialog.addNumber("Maximum object circularity:", maxObjectCircularity);
Dialog.show();
autoThresholdMethod = Dialog.getChoice();
gaussianBlurRadius = Dialog.getNumber();
minObjectSize = Dialog.getNumber();
maxObjectSize = Dialog.getNumber();
minObjectCircularity = Dialog.getNumber();
maxObjectCircularity = Dialog.getNumber();
//to log
print("Segmentation parameters:\nGaussian radius =",gaussianBlurRadius,"; Background subtraction =",rollingBallRadius,"; Auto Threshold Method =",autoThresholdMethod,"\nMinimum object size =",minObjectSize,"; Maximum object size =",maxObjectSize,"Minimum object circularity =",minObjectCircularity,"; Maximum object circularity =",maxObjectCircularity,";");

//getDialogImageFileFilter();
//get file list ALL
fileList = getFileListSubfolder(inputPath);  //read all files without subfolders
fileList = getFileType(fileList);			 //filter for extension
fileList = getFilteredFileList(fileList);    //filter for strings
wellList = getUniqueWellListCV7000(fileList);//list of wells to process

waitForUser("Do you really want to open " + fileList.length + " files?" + "\n\n" + "Otherwise press 'ESC' and check image list and filter text!");

for (currentWell = 0; currentWell < wellList.length; currentWell++) {
	currentFileList = getFilteredList(fileList, wellList[i]);

	setBatchMode(batchMode);
	//go through all files in current file list
	for (currentFile = 0; currentFile < currentFileList.length; currentFile++) {
		if (endsWith(fileList[currentFile],".tif")) {   //check if it is right file and handle error on open()
			IJ.redirectErrorMessages();
			showProgress(currentFile / currentFileList.length);
			showStatus("processing" + currentFileList[currentFile]);
			print(currentFileList[currentFile]);
			open(currentFileList[currentFile]);
			}
		run("Images to Stack", "name=Stack title=[] use");
		stackName = getTitle();
		getDimensions(width, height, channels, slices, frames);
		run("Select None");
		run("Clear Results");
		for (slice = 1; slice  <= slices; slice++) {
			if (isOpen("ROI Manager")) {
				selectWindow("ROI Manager");
				run("Close");
				}
			setBatchMode(true);	
			selectWindow(stackName);
			setSlice(slice);
			run("Duplicate...", "title=[" + stackName + "_ch" + slice + "] duplicate range=" + slice + "-" + slice);
			beadImage = getTitle();
			//setBatchMode(true);
			run("Duplicate...", " ");
			tempImage = getTitle();
			waitForUser("test");
			run("Gaussian Blur...", "sigma=" + gaussianBlurRadius);   
			//waitForUser("analyse!");
			run("Auto Threshold", "method=" + autoThresholdMethod + " ignore_black ignore_white white"); 
			run("Watershed");
			run("Analyze Particles...", "size=" + minObjectSize + "-" + maxObjectSize + " circularity=" + minObjectCircularity + "-" + maxObjectCircularity + " show=[Outlines] exclude clear add");
			selectWindow(tempImage);
			close();
			selectWindow("Drawing of " + tempImage);
			saveAs("PNG", outputPath + "Drawing of " + tempImage + ".png");
			close();
			selectWindow(beadImage);
			run("Select None");
			for (i=0; i < roiManager("count"); i++) {
				roiManager("Select", i);
				roiManager("Measure");
				}
			saveAs("Results", outputPath + currentFileList[currentFile] + "_ch" + slice + ".txt");
			updateResults();
			setBatchMode(false);
			selectWindow(beadImage);
			close();
			selectWindow(stackName);
			close();
			}  	
		} else { //if file has different extensionn
		print("file (" + (currentFile + 1) + "/" + currentFileList.length + "): ", currentFileList[currentFile], " was skipped."); 	//if not a folder
		}		
	}
				
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
selectWindow("Log");
if(outputPath != "not available") {
	saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
	if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	
	}
/////////////////////////////////////////////////////////////////////////////////////////////
////////			F U N C T I O N S				/////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//function open dialog to set image file list filter
function getDialogImageFileFilter() {
Dialog.create("Image file filter...");  //enable use inveractivity
Dialog.addMessage("Define the files to be processed:");
Dialog.addString("Files should have this extension:", fileExtension);	//add extension
Dialog.addMessage("Define filter for files:");
for (i = 0; i < 3; i++) {
	Dialog.addString((i + 1) + ") Filter this text from file list: ", filterStrings[i]);	
	Dialog.addChoice((i + 1) + ") Files with text are included/excluded?", availableFilterTerms, filterTerms[i]);	
	}
Dialog.addCheckbox("Check file lists?", displayFileList);	//if check file lists will be displayed
Dialog.show();
fileExtension = Dialog.getString();
for (i = 0; i < 3; i++) {
	filterStrings[i] = Dialog.getString();	
	filterTerms[i] = Dialog.getChoice();	
	}
displayFileList = Dialog.getCheckbox();
}

//function get all files from folders and all subfolders
function getFileListSubfolder(inputPath) {
fileList = getFileList(inputPath);  //read file list
Array.sort(fileList);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileList.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileList[i], "/"))) fileList[i] = replace(fileList[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileList[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPath + fileList[i]);
		returnedFileList = Array.concat(returnedFileList, returnedFileListTemp);
		} else {  									//if it is a file
		returnedFileList = Array.concat(returnedFileList, inputPath + fileList[i]);
		//print(i, inputPath + fileList[i]);
		}
	}
return returnedFileList;
}

//function get all folders from a folder
function getFolderList(inputPathFunction) {
fileListFunction = getFileList(inputPathFunction);  //read file list
Array.sort(fileListFunction);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileListFunction.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileListFunction[i], File.separator))  returnedFileList = Array.concat(returnedFileList,fileListFunction[i]);//if it is a folder
	}
print(returnedFileList.length + " folders were found."); 
if (displayFileList) {Array.show("Found folders",returnedFileList);}	
return returnedFileList;
}

//function finds all files with certain extension
function getFileType(fileList) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
if(lengthOf(fileExtension) > 0) {
	for (i = 0; i < fileList.length; i++) {
		if (endsWith(fileList[i],fileExtension)) returnedFileList = Array.concat(returnedFileList,fileList[i]);
		}
	print(returnedFileList.length + " files found with extension " + fileExtension + ".");
	if (displayFileList) {Array.show("All files - filtered for " + fileExtension, returnedFileList);} 
	} else {
	returnedFileList = fileList;	
	}
return returnedFileList;
}

//function filter a file list for a certain string
function getFilteredFileList(fileList) {
skippedFilter = 0;	
for (i = 0; i < filterStrings.length; i++) {
	if (filterTerms[i] != availableFilterTerms[0]) {
		returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
		for (j = 0; j < fileList.length; j++) {
			if (filterTerms[i] == "include" && indexOf(fileList[j],filterStrings[i]) != -1) returnedFileList = Array.concat(returnedFileList,fileList[j]);
			if (filterTerms[i] == "exclude" && indexOf(fileList[j],filterStrings[i]) <= 0) returnedFileList = Array.concat(returnedFileList,fileList[j]);
			}
		print(returnedFileList.length + " files found after filter: " + filterTerms[i] + " text " + filterStrings[i] + "."); 
		if (displayFileList) {Array.show("List of files - after filtering for " + filterStrings[i], returnedFileList);}
		fileList = returnedFileList;
		} else skippedFilter++;
	} 
if (skippedFilter == filterStrings.length) returnedFileList = fileList;	//if no filter condition is selected
return returnedFileList;
}

//function filter a list for a certain string (filter)
function getFilteredList(inputList, filterStringFunction) {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " files found after filtering: " + filterStringFunction); 
if (displayList) {Array.show("List after filtering for " + filterStringFunction, returnedFileList);}
return returnedList;
}

//function returnes the unique values of an array
function getUniqueArrayValues(inputArray) {
outputArray = newArray(inputArray[0]);		//outputArray stores unique values, here initioalitaion with first element of inputArray 
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for outputArray
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (outputArray.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		if(outputArray[j] == inputArray[i]) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) outputArray = Array.concat(outputArray,inputArray[i]);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(outputArray.length + " unique values found."); 
if (displayList) {Array.show("List of " + outputArray.length + " unique values", outputArray);}	
return outputArray;
}

//function returnes the unique wells of an array of CV7000 files
function getUniqueWellListCV7000(inputArray) {
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
if (displayFileList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////

