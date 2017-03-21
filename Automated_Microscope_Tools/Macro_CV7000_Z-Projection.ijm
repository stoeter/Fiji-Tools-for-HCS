//CV7000-Z-Projection
macroName = "CV7000-Z-Projection";
macroShortDescription = "This macro opens CV7000 images of a well-field-channel and does a z projection.";
macroDescription = "This macro reads single CV7000 images of a well as .tif ." +
	"<br>The chosen folder will be searched for images including subfolders." +
	"<br>All images of a unique well, field and channel are opened and projected." +
	"<br>All z-projection methods selectable.";
macroRelease = "first release 06-10-2015 by Martin Stoeter (stoeter(at)mpi-cbg.de)";
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
print(macroName,"\nStart:",year + "-" + month + "-" + dayOfMonth + ", h" + hour + "-m" + minute + "-s" + second);
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
defaultFilterStrings = newArray("DC_sCMOS #","SC_BP","");
print("Files containing these strings will be automatically filtered out:");
Array.print(defaultFilterStrings);
saveStack = false;

//set array variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("no filtering", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();

print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);
print("Processing file list...");

//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings
if (fileList.length == 0) exit("No files to process");  

filterStrings = newArray("DC_sCMOS #","SC_BP","");
filterTerms = newArray("exclude", "exclude", "no filtering"); 
print("removing correction files from file list containing text", filterStrings[0], filterStrings[1], filterStrings[2]);
fileList = getFilteredFileList(fileList, false, false);
if (fileList.length == 0) exit("No files to process");  

wellList = getUniqueWellListCV7000(fileList, displayFileList);
wellFieldList = getUniqueWellFieldListCV7000(fileList, displayFileList);
fieldList = getUniqueFieldListCV7000(fileList, displayFileList);
channelList = getUniqueChannelListCV7000(fileList, displayFileList);
print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n");
stackSize = fileList.length / wellFieldList.length / channelList.length;
print("Assuming stacks with ", stackSize, "planes. Please check if this is correct!");

//set projection type
Dialog.create("Set projection type");
Dialog.addChoice("Projection:", availableProjectionTerms);	//set number of images in one row
Dialog.addNumber("Lowest plane:", 1);
Dialog.addNumber("Highest plane:", stackSize);
Dialog.addCheckbox("Save Z-stack instead of projection?", saveStack);	//if checked no projection will be done and image will be saves as stack
Dialog.addCheckbox("Set batch mode (hide images)?", batchMode);	//if checked no images will be displayed
Dialog.show();
projectionType = Dialog.getChoice();
Zstart = Dialog.getNumber();
Zstop = Dialog.getNumber();
saveStack = Dialog.getCheckbox();
batchMode = Dialog.getCheckbox();
print("Selected projection type:", projectionType, "starting from plane", Zstart, "until plane",Zstop);

print("===== starting processing.... =====");
setBatchMode(batchMode);

//go through all files
for (currentWellField = 0; currentWellField < wellFieldList.length; currentWellField++) {   // well by well
print("well-field (" + (currentWellField + 1) + "/" + wellFieldList.length + ") ...");  //to log window
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel per well
		//define new filters and filter file list for currentWell and currentChannel
		filterStrings = newArray(wellFieldList[currentWellField],channelList[currentChannel] + ".tif","");      //pre-definition of strings to filter, add "_" because well strings e.g. A03, L01, C02 can be in file name at other places, e.g ..._A06_T0001F001L01A03Z01C02.tif and ".tif" to excluse well C02 instead of channel C02
		filterTerms = newArray("include", "include", "no filtering");  //pre-definition of filter types 
		wellChannelFileList = getFilteredFileList(fileList, false, false);
		//now open all files (wellChannelFileList) that belong to one wellField in one channel
		for (currentFile = 0; currentFile < wellChannelFileList.length; currentFile++) {
			//image sequence & regEx would be possible, but it seems to be slow: run("Image Sequence...", "open=Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\ file=(_B03_.*C01) sort");
			IJ.redirectErrorMessages();
			if (File.exists(wellChannelFileList[currentFile])) {
				open(wellChannelFileList[currentFile]);
				currentImage = getTitle();
				print("opened (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
				} else {
				print("file not found (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
				}
			showProgress(currentFile / wellChannelFileList.length);
	       	showStatus("processing" + fileList[currentFile]);
			} //end for all images per channel	
		//waitForUser("done");	
		if (nImages > 1) {
			run("Images to Stack", "name=Stack title=[] use");
			if (!saveStack) run("Z Project...", "start=" + Zstart + " stop=" + Zstop + " projection=[" + projectionType + "]");
			outputFileName = substring(currentImage,0,lengthOf(currentImage)-9) + "all" + substring(currentImage,lengthOf(currentImage)-7,lengthOf(currentImage));
			saveAs("Tiff", outputPath + outputFileName);
			close();  //Z projection
			if (!saveStack) {
				print("saved projection as " + outputPath + outputFileName);  //to log window
				selectWindow("Stack"); //stack
				close();
				} else {
				print("saved image stack as " + outputPath + outputFileName);  //to log window	
				}
			} else {  //end if images are open
			run("Close All");
			}
		} //end for all channels in well			
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
	}  //end for all wells
			
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
if (lastIndexOf(inputArray[0],"_T00") > 0) { //check first well
	currentWell = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00"));   //first well found
	} else {
	print("no well found in path:", inputArray[i]);	
	exit("No well information found in file name. Please double-check the file filtering...");
	}	
returnedWellList = newArray(currentWell);     //this list stores all unique wells found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned well list
	valueUnique = true;						//as long as value was not found in array of unique values
	if (lastIndexOf(inputArray[i],"_T00") > 0) {  // if CV7000 file names are recognized
		while (valueUnique && (returnedWellList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
			currentWell = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00"));
			if (returnedWellList[j] == currentWell) {
				valueUnique = false;			//if value was found in array of unique values stop while loop
				} else {
				j++;
				}
			}  //end while
		} else {
		print("no well found in path:", inputArray[i]);	
		}		
	if (valueUnique) returnedWellList = Array.concat(returnedWellList, currentWell);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellList.length + " well(s) found."); 
Array.sort(returnedWellList);
if (displayList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}

//function returnes the unique well files (all fields of all wells, e.g. G10_T0001F001) of an array of CV7000 files
//example: myUniqueWellFileds = getUniqueWellFieldListCV7000(myList, true);
function getUniqueWellFieldListCV7000(inputArray, displayList) {
if (lastIndexOf(inputArray[0],"_T00") > 0) { //check first well field
	currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00")+10);   //first well field found
	} else {
	print("no well found in path:", inputArray[i]);	
	exit("No well field information found in file name. Please double-check the file filtering...");
	}
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
//print("start:", currentWellField, returnedWellFieldList.length);
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	if (lastIndexOf(inputArray[i],"_T00") > 0) {  // if CV7000 file names are recognized
		while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
			currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00")+10);
			//print(i,j,currentWellField, returnedWellFieldList[j]);
			if(returnedWellFieldList[j] == currentWellField) {
				valueUnique = false;			//if value was found in array of unique values stop while loop
				} else {
				j++;
				}
			}  //end while
		} else {
		print("no well field found in path:", inputArray[i]);	
		}		
	//print("final:", currentWellField, valueUnique, returnedWellFieldList.length);
	if (valueUnique) returnedWellFieldList = Array.concat(returnedWellFieldList, currentWellField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellFieldList.length + " well field(s) found."); 
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












