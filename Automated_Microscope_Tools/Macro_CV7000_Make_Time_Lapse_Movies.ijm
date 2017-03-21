//CV7000-Make-Time-Lapse-Movies
macroName = "CV7000-Make-Time-Lapse-Movies";
macroShortDescription = "This macro finds all images of well positions of CV7000 and saves them as movies.";
macroDescription = "This macro saves time lapse images of CV7000 as movies." +
	"<br>CV7000 images will be opened as image sequence using well, field and acquisition number as RegEx." + 
	"<br>- Select input folder" +
	"<br>- Select ouput folder for saving files (.tif and/or .avi (select compression and frame rate))" + 
	"<br>- Multiple acquisition numbers can be selected and will be concatenated (channel handling not yet implemented)" +
	"<br>HINT: keep default search term '_T0001' (first image) for finding wells, fields and acquisitions";
macroRelease = "first release 01-03-2017 by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;
macroHtml = "<html>" 
	+"<font color=red>" + macroName + "\n" + macroRelease + "</font> <br> <br>"
	+"<font color=black>" + macroDescription + "</font> <br> <br>"
	+"<font color=black>Check for more help on this web page:</font> <br>"
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
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools-for-HCS by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min integrated median stack display redirect=None decimal=3");
run("Input/Output...", "jpeg=90 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("_T0001","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("include", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();
print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

//get file list ALL
//fileList = getFileList(inputPath);
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings

uniqueWellFields = getUniqueWellFieldListCV7000(fileList, false);
uniqueAcquisitions = getUniqueAcquisitionListCV7000(fileList, false);
useAcquisitionsBooleanLists = newArray(uniqueAcquisitions.length);
//uniqueChannels = getUniqueChannelListCV7000(fileList, true);
//useChannelsBooleanLists = newArray(uniqueChannels.length);

// settings for move generation
availableAVIcompressions = newArray("None", "JPEG", "PNG");
framesPerSec = 5;

Dialog.create("Settings for movie generation");
Dialog.addCheckbox("Save as .tif?", true);
Dialog.addCheckbox("Save as .avi?", false);
Dialog.addChoice("Compression for .avi:", availableAVIcompressions);
Dialog.addMessage("Select the acquisition numbers to use:");
for (currentAcquisition = 0; currentAcquisition < uniqueAcquisitions.length; currentAcquisition++) Dialog.addCheckbox("Use acquisition " + uniqueAcquisitions[currentAcquisition], true);
//Dialog.addMessage("Select the channels to use:");
//for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) Dialog.addCheckbox("Use acquisition " + uniqueChannels[currentChannel], true);
Dialog.addNumber("Frames per seconds?", framesPerSec);
Dialog.addCheckbox("Hide image display?", true);
Dialog.show(); 
saveTif = Dialog.getCheckbox();
saveAvi = Dialog.getCheckbox();
aviCompression = Dialog.getChoice();
for (currentAcquisition = 0; currentAcquisition < uniqueAcquisitions.length; currentAcquisition++) {
	useAcquisitionsBooleanLists[currentAcquisition] = Dialog.getCheckbox();
	print("Acquisition -", uniqueAcquisitions[currentAcquisition], ":", useAcquisitionsBooleanLists[currentAcquisition]);
	}
//for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) useChannelBooleanLists[currentChannel] = Dialog.getCheckbox();
framesPerSec = Dialog.getNumber();
hideImages = Dialog.getCheckbox();
print("save movie as .tif -" + saveTif + "- and as .avi -" + saveAvi + "- with", aviCompression, "compression"); 
print("save movie with", framesPerSec, "frames per second; hide images", hideImages); 


//start processing...
setBatchMode(hideImages);
for (currentWellField = 0; currentWellField < uniqueWellFields.length; currentWellField++) {
	showProgress(currentWellField / uniqueWellFields.length);
	
	// open well field data one after the other...
	currentWell = substring(uniqueWellFields[currentWellField], 0, 3);
	currentField = substring(uniqueWellFields[currentWellField], lengthOf(uniqueWellFields[currentWellField])-4, lengthOf(uniqueWellFields[currentWellField]));
	imageSequenceCounter = 0;

	for (currentAcquisition = 0; currentAcquisition < uniqueAcquisitions.length; currentAcquisition++) {
		if (useAcquisitionsBooleanLists[currentAcquisition]) {
			imageSequenceCounter++;  // only add one count if acquisition number ist actually enables and will be loaded 
			print("( " + (currentWellField+1) + " / " + uniqueWellFields.length + " ) open images with regex:", currentWell, currentField, uniqueAcquisitions[currentAcquisition]);
			IJ.redirectErrorMessages();
			run("Image Sequence...", "open=" + inputPath + " file=(.*_" + currentWell + "_.*" + currentField + ".*" + uniqueAcquisitions[currentAcquisition] + ".*) sort");
			if (nImages == imageSequenceCounter) { // see imageSequenceCounter above
				currentImage = getTitle();
				currentImage = currentImage + "_" + currentWell + "_" + currentField + "_" + uniqueAcquisitions[currentAcquisition];
				rename(currentImage);
				print("opened ", nSlices, " images:", currentImage);
				} else {
				print("no images found");	// run Image Sequence silently failed...
				}
			} //end if
		}  //end for acquistitions
	
	if (nImages > 1) run("Concatenate...", "all_open title=Movie");
		
	//Save the image file
	if (saveTif) {
		saveAs("Tiff", outputPath + currentImage + ".tif");
		print("saved", outputPath + currentImage + ".tif");
		}
	if (saveAvi) {
		run("AVI... ", "compression=" + aviCompression + " frame=" + framesPerSec + " save=" + outputPath + currentImage + ".avi");
		print("saved", outputPath + currentImage + ".avi");
		}
	close();
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber +".txt");		
	}  //end well fields

//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 

/////////////////////////////////////////////////////////////////////////////////////////////
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////

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

//function filters a list for a certain string (filter)
//example: myList = getFilteredList(myList, "myText", true);
function getFilteredList(inputList, filterStringFunction, displayList) {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " files found after filtering: " + filterStringFunction); 
if (displayList) {Array.show("List after filtering for " + filterStringFunction, returnedFileList);}
return returnedList;
}

//function gets all files from folders and subfolders
//example: myFileList = getFileListSubfolder("/home/myFolder/", true);
function getFileListSubfolder(inputPathFunction, displayList) {
fileListFunction = getFileList(inputPathFunction);  //read file list
Array.sort(fileListFunction);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i = 0; i < fileListFunction.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileListFunction[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPathFunction + fileListFunction[i],displayList);
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

//function returns a number in specific string format, e.g 2.5 => 02.500
//example: myStringNumber = getNumberToString(2.5, 3, 6);
function getNumberToString(number, decimalPlaces, lengthNumberString) {
numberString = "000000000000" + toString(number, decimalPlaces);  //convert to number to string and add zeros in the front
numberString = substring(numberString, lengthOf(numberString) - lengthNumberString, lengthOf(numberString)); //shorten string to lengthNumberString
return numberString;
}

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

//function saves the log window in the given path
//example: saveLog("C:\\Temp\\Log_temp.txt");
function saveLog(logPath) {
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
saveAs("Text", logPath);
if (nImages > 0) selectWindow(currentWindow);
}

//function returnes the unique fields (all fields of all wells, e.g. F001, F002,...) of an array of CV7000 files
//example: myUniqueFields = getUniqueFieldListCV7000(myList, true);
function getUniqueFieldListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No fields found!");
	return newArray(0);
	}
currentField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+6,lastIndexOf(inputArray[0],"_T00")+10);   //first field found
returnedFieldList = Array.concat(currentField);     //this list stores all unique fields found and is returned at the end of the function
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

//function returns the unique well fields (all fields of all wells, e.g. G10_T0001F001) of an array of CV7000 files
//example: myUniqueWellFields = getUniqueWellFieldListCV7000(myList, true);
function getUniqueWellFieldListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No well fields found!");
	return newArray(0);
	}
currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00")+10);   //first well field found
returnedWellFieldList = Array.concat(currentWellField);     //this list stores all unique well fields found and is returned at the end of the function
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00")+10);
		if(returnedWellFieldList[j] == currentWellField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedWellFieldList = Array.concat(returnedWellFieldList, currentWellField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellFieldList.length + " wells fields found."); 
Array.sort(returnedWellFieldList);
if (displayList) {Array.show("List of " + returnedWellFieldList.length + " unique well fields", returnedWellFieldList);}	
return returnedWellFieldList;
}

//function returnes the unique wells of an array of CV7000 files
//example: myUniqueWells = getUniqueWellListCV7000(myList, true);
function getUniqueWellListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No wells found!");
	return newArray(0);
	}
currentWell = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00"));   //first well found
returnedWellList = Array.concat(currentWell);     //this list stores all unique wells found and is returned at the end of the function
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

//function returnes the unique acquisition numbers of an array of CV7000 files
//example: myUniqueWells = getUniqueAcquisitionListCV7000(myList, true);
function getUniqueAcquisitionListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No wells acquisition number found!");
	return newArray(0);
	}
currentAcquisition = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+13,lastIndexOf(inputArray[0],"_T00")+16);   //first acquisition found
returnedAcquisitionList = Array.concat(currentAcquisition);     //this list stores all unique cquisitions found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned cquisition list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedAcquisitionList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentAcquisition = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")+13,lastIndexOf(inputArray[i],"_T00")+16);
		if(returnedAcquisitionList[j] == currentAcquisition) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedAcquisitionList = Array.concat(returnedAcquisitionList, currentAcquisition);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedAcquisitionList.length + " acquisition numbers found."); 
Array.sort(returnedAcquisitionList);
if (displayList) {Array.show("List of " + returnedAcquisitionList.length + " unique acquisition numbers", returnedAcquisitionList);}	
return returnedAcquisitionList;
}

