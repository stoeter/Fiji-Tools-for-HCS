//CV7000_Illumination_Correction
macroName = "CV7000_Illumination_Correction";
macroShortDescription = "This macro opens CV7000 images and applies and illumination correction.";
macroDescription = "This macro reads single CV7000 images as .tif ." +
	"<br>The chosen folder will be searched for images including subfolders." +
	"<br>Illumination correction images are read from a folder and " +
	"<br>assigned to a channel within the macro." +
	"<br>Imagesa are divided through the normalized illumination image.";
macroRelease = "first release 07-10-2015 by Martin Stoeter (stoeter(at)mpi-cbg.de)";
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
//var inputPath = "T:\\projects\\Other_small_projects\\Shamba_PGL3_droplets\\cv7000images\\150923-PGL3-salts-2ndTimePoint_20150923_124739\\test\\";
//var outputPath = "T:\\projects\\Other_small_projects\\Shamba_PGL3_droplets\\cv7000images\\150923-PGL3-salts-2ndTimePoint_20150923_124739\\result\\";
//var correctionImagePath = "T:\\projects\\Other_small_projects\\Shamba_PGL3_droplets\\150923-PGL3-salts\\imageAnalysis\\illumCorrection\\";
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
correctionImagePath = getDirectory("Choose folder with illumination correction images...");

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";\ncorrectionImagePath = \"" + correctionImagePath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
//run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 

//set variables
batchMode = false;
availableProjectionTerms = newArray("Max Intensity", "Sum Slices", "Average Intensity", "Min Intensity", "Standard Deviation", "Median");

//set array variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("back","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("exclude", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();

print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
//filterStrings = newArray("back","C03","");
//filterTerms = newArray("exclude", "include", "no filtering"); 
fileList = getFilteredFileList(fileList, false, displayFileList);  //filter for strings

wellList = getUniqueWellListCV7000(fileList, displayFileList);
wellFieldList = getUniqueWellFieldListCV7000(fileList, displayFileList);
fieldList = getUniqueFieldListCV7000(fileList, displayFileList);
channelList = getUniqueChannelListCV7000(fileList, displayFileList);
print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n");
print("===== checking illumination image.... =====");
batchMode = true;
setBatchMode(batchMode);

fileListIllumImg = getFileListSubfolder(correctionImagePath, displayFileList);  //read all files in subfolders
fileListIllumImg = getFileType(fileListIllumImg, fileExtension, displayFileList);
illumImgList = newArray(fileListIllumImg.length);
print(fileListIllumImg.length, "illumination images found");

for (currentIllumImg = 0; currentIllumImg < fileListIllumImg.length; currentIllumImg++) {
	open(fileListIllumImg[currentIllumImg]);
	illumImgList[currentIllumImg] =  getTitle();
	getDimensions(width, height, channels, slices, frames);
	getStatistics(area, mean, min, max);
	print("opened (" + (currentIllumImg + 1) + "/" + fileListIllumImg.length + "):", fileListIllumImg[currentIllumImg]);  //to log window
	print("width :", width, "\nheight :", height, "\nmean :", mean, "\nminimum :", min, "\nmaximum: ", max);
	}

//define illumination correction images for each channel
print("===== assignment of illumination images to channels.... =====");
Dialog.create("Set illumination correction image for each channel");
for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel
	Dialog.addChoice("Channel - " + channelList[currentChannel], illumImgList);	//set illumination images for each channel
	}
Dialog.addCheckbox("Set batch mode (hide images)?", batchMode);	//if checke no images will be displayed
Dialog.show();
for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel
	illumImgList[currentChannel] = Dialog.getChoice();
	print("Channel - " + channelList[currentChannel], "will be corrected with this image:\n" + illumImgList[currentChannel]);
}
batchMode = Dialog.getCheckbox();

//check if output folder is empty
filesInOutPutFolder = getFileList(outputPath);
if (filesInOutPutFolder.length > 0) {
	print("chosen output path countains", filesInOutPutFolder.length, "files.\nATTENTION!!!\nImage might be overwritten!");
	Dialog.create("Output folder is not empty!")
	Dialog.addMessage("Chosen output path contains " + filesInOutPutFolder.length + " files. \nATTENTION!!!\nImage might be overwritten!\nPress 'Cancel' to quit!");
	Dialog.show(); 
	}

print("===== starting processing.... =====");
setBatchMode(batchMode);
//go through all files
for (currentWell = 0; currentWell < wellList.length; currentWell++) {   // well by well
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel per well
		//define new filters and filter file list for currentWell and currentChannel
		filterStrings = newArray(wellList[currentWell],channelList[currentChannel] + ".tif","");      //pre-definition of strings to filter, add "_" because well strings e.g. A03, L01, C02 can be in file name at other places, e.g ..._A06_T0001F001L01A03Z01C02.tif and ".tif" to excluse well C02 instead of channel C02
		filterTerms = newArray("include", "include", "no filtering");  //pre-definition of filter types 
		wellChannelFileList = getFilteredFileList(fileList, false, false);
		//now open all files (wellChannelFileList) that belong to one wellField in one channel
		for (currentFile = 0; currentFile < wellChannelFileList.length; currentFile++) {
			//image sequence & regEx would be possible, but it seems to be slow: run("Image Sequence...", "open=Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\ file=(_B03_.*C01) sort");
			IJ.redirectErrorMessages();
			open(wellChannelFileList[currentFile]);
			currentImage = getTitle();
			bitType = bitDepth(); 
			showProgress(currentFile / wellChannelFileList.length);
	       	showStatus("processing" + fileList[currentFile]);
			print("opened (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
			//apply illumination correction, first divide through the correction image (normalized to max intensity = 10000), and then multiply with 10000 to get normalized values
			imageCalculator("Divide create 32-bit", currentImage, illumImgList[currentChannel]);
			correctedImage = getTitle();
			run("Multiply...", "value=10000.000");
			//resetMinAndMax();
			run(bitType + "-bit");
			selectWindow(currentImage); //currentImage
			close();
			//save corrected images
			selectWindow(correctedImage); //correctedImage
			saveAs("Tiff", outputPath + currentImage);
			print("saved corrected image as " + currentImage);  //to log window
			close();  //corrected image
			} //end for all images per channel	
		//waitForUser("done");
		} //end for all channels in well			
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
	}  //end for all wells

for (currentImage = 0; currentImage < fileListIllumImg.length; currentImage++) {  // channel by channel
	selectWindow(illumImgList[currentImage]); //IllumImg
	close();
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
		print(returnedFileList.length + " files found after filter: " + filterTerms[i] + " text " + filterStrings[i] + "."); 
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
	print(returnedFileList.length + " files found in selected folder and subfolders."); 	
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
	print(returnedFileList.length + " files found with extension " + fileExtension + ".");
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
print(returnedList.length + " files found after filtering: " + filterStringFunction); 
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
print(returnedFieldList.length + " fields found."); 
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
print(returnedChannelList.length + " channels found."); 
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












