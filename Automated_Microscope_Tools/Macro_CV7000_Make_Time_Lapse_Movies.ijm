//CV7000-Make-Time-Lapse-Movies
macroName = "Macro-CV7000-Make-Time-Lapse-Movies";
macroShortDescription = "This macro finds all images of well positions of CV7000 and saves them as movies.";
macroDescription = "This macro saves time lapse images of CV7000 as movies." +
	"<br>CV7000 images will be opened as image sequence using well, field and acquisition number as RegEx." + 
	"<br>- Select input folder" +
	"<br>- Select ouput folder for saving files (.tif and/or .avi (select compression and frame rate))" + 
	"<br>- Multiple acquisition numbers can be selected" +
	"<br>- Acquisitions can be saved as separate files, as concatenated series or as merged channels" +
	"<br>- If channel info is used acquisition info is ignored. " +
	"<br>HINT: keep default search term '_T0001' (first image) for finding wells, fields and acquisitions";
macroRelease = "fourth release 31-03-2018";
macroAuthor = "by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;
macroHtml = "<html>" 
	+"<font color=red>" + macroName + "\n" + macroRelease + " " + macroAuthor + "</font> <br> <br>"
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
print(macroName, "(" + macroRelease + ")", "\nStart:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
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
print("This Image File Filter will find the first time point (T0001) for each imges series and will extract meta data from those file names...");
setDialogImageFileFilter();
print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

//get file list ALL
//fileList = getFileList(inputPath);
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings

uniqueWellFields = getUniqueWellFieldListCV7000(fileList, displayFileList);
uniqueAcquisitions = getUniqueAcquisitionListCV7000(fileList, displayFileList);
uniqueChannels = getUniqueChannelListCV7000(fileList, displayFileList);
uniqueTimeLines = getUniqueTimeLineListCV7000(fileList, displayFileList);
uniqueTimeLineAcquisitions = getUniqueTimeLineAcquisitionListCV7000(fileList, displayFileList);
if(displayFileList) waitForUser("Take a look at the list windows...");  //give user time to analyse the lists  

useAcquisitionsBooleanLists = newArray(uniqueAcquisitions.length);
useChannelsBooleanLists = newArray(uniqueChannels.length);

// settings for move generation
availableAVIcompressions = newArray("None", "JPEG", "PNG");
framesPerSec = 5;
availableAcquisitonOptions = newArray("Keep separate files", "Concatenate as series", "Merge as channels");
availableTimeLineOptions = newArray("Ignore time lines", "Process time lines separately");
ignoreAcquisitionsUseChannels = false;
make8bit = false;

Dialog.create("Settings for movie generation");
Dialog.addCheckbox("Save as .tif?", true);
Dialog.addCheckbox("Save as .avi?", false);
Dialog.addChoice("Compression for .avi:", availableAVIcompressions);
Dialog.addNumber("Frames per seconds?", framesPerSec);
Dialog.addMessage("Select the acquisition numbers to use:");
for (currentAcquisition = 0; currentAcquisition < uniqueAcquisitions.length; currentAcquisition++) Dialog.addCheckbox("Use acquisition " + uniqueAcquisitions[currentAcquisition], true);
Dialog.addChoice("How to treat multiple acquisitions?", availableAcquisitonOptions);
Dialog.addChoice("How to treat multiple time lines?", availableTimeLineOptions);
Dialog.addCheckbox("Use channels instead of acquisitions?", ignoreAcquisitionsUseChannels);
Dialog.addCheckbox("Adjust contrast and make 8-bit?", make8bit);
Dialog.addCheckbox("Hide image display?", true);
Dialog.show(); 
saveTif = Dialog.getCheckbox();
saveAvi = Dialog.getCheckbox();
aviCompression = Dialog.getChoice();
framesPerSec = Dialog.getNumber();
for (currentAcquisition = 0; currentAcquisition < uniqueAcquisitions.length; currentAcquisition++) {
	useAcquisitionsBooleanLists[currentAcquisition] = Dialog.getCheckbox();
	print("Acquisition -", uniqueAcquisitions[currentAcquisition], ":", useAcquisitionsBooleanLists[currentAcquisition]);
	}
acquisitonOption = Dialog.getChoice();
timeLineOption = Dialog.getChoice();
ignoreAcquisitionsUseChannels = Dialog.getCheckbox();
make8bit = Dialog.getCheckbox();
hideImages = Dialog.getCheckbox();
print("save movie as .tif -" + saveTif + "- and as .avi -" + saveAvi + "- with", aviCompression, "compression"); 
print("Treat acquisitions:" + acquisitonOption + ", treat time lines:" + timeLineOption, ", ignore acquisition and use channel info:", ignoreAcquisitionsUseChannels); 
print("save movie with", framesPerSec, "frames per second; hide images", hideImages); 

if (ignoreAcquisitionsUseChannels) {
	Dialog.create("Settings for movie generation");
	Dialog.addMessage("Ignoring acqusitions, channel info will be used...");
	Dialog.addMessage("Select the channels to use:");
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) Dialog.addCheckbox("Use acquisition " + uniqueChannels[currentChannel], true);
	Dialog.show(); 
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) {
		useChannelsBooleanLists[currentChannel] = Dialog.getCheckbox();
		print("Channel -", uniqueChannels[currentChannel], ":", useChannelsBooleanLists[currentChannel]);
		}
	}	

//set variables according to user dialogs
contrastValueArray = newArray(100,355,100,355,100,355,100,355,100,355);  //vector of alternating min-max contrast values => newArray(ch1-min,ch1-max,ch2-min,ch2-max,ch3-min, ...)
//fileEndArray = newArray("C01.tif","C02.tif","C03.tif","C04.tif");  //vector of a file endings of individual channels
channelToRGBArray = newArray("3","2","1");   //vector of colors (RGB channel numbers) assigned to file endings
if (make8bit) {
	print("intensities of channels will be adjusted and images will be converted to 8-bit..."); 
	print("for RGB merges colors have these channel numbers: Red = 1, Green = 2, Blue = 3");
	fileTag = "_RGB";
	Dialog.create("Set contrast values for RGB merge");
	Dialog.addMessage("Red = 1, Green = 2, Blue = 3");
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) {
		Dialog.addMessage("--------------------------------------------");
		Dialog.addChoice("Color of channel ends with " + uniqueChannels[currentChannel] + ":", channelToRGBArray, channelToRGBArray[currentChannel]);	 //which channel is which color in RGB
		Dialog.addNumber("Set minimum intensity channel " + uniqueChannels[currentChannel] +":", contrastValueArray[currentChannel * 2]);	//set value for min
		Dialog.addNumber("Set maximum intensity channel " + uniqueChannels[currentChannel] +":", contrastValueArray[currentChannel * 2 + 1]);	//set value for max
		}
	Dialog.show();
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) {
		channelToRGBArray[currentChannel] = Dialog.getChoice();
		contrastValueArray[currentChannel * 2] = Dialog.getNumber();
		contrastValueArray[currentChannel * 2 + 1]  = Dialog.getNumber();
		print("channel " + uniqueChannels[currentChannel] + ": ends with", uniqueChannels[currentChannel], "is assigned to RGB channel", channelToRGBArray[currentChannel] + ", contrast min =", contrastValueArray[currentChannel * 2], "and max =", contrastValueArray[currentChannel * 2 + 1]);  
		}
	} 

//start processing...
setBatchMode(hideImages);
for (currentWellField = 0; currentWellField < uniqueWellFields.length; currentWellField++) {
	showProgress(currentWellField / uniqueWellFields.length);
	
	// open well field data one after the other...
	currentWell = substring(uniqueWellFields[currentWellField], 0, 3);
	currentField = substring(uniqueWellFields[currentWellField], lengthOf(uniqueWellFields[currentWellField])-4, lengthOf(uniqueWellFields[currentWellField]));

	mergeChannelsString = "";
	if (acquisitonOption ==  "Ignore time lines") {
		uniqueTimeLines = newArray("");
		//uniqueTimeLineAcquisitions;  // combine time line with acquisitions => unique values and iteration over regex is combination of time line and acquisition (TimeLineAcquisitions)
//		if(displayFileList) {
//			Array.show("List of " + uniqueTimeLineAcquisitions.length + " unique time line acquisitions", uniqueTimeLineAcquisitions);
//			waitForUser("Take a look at the list windows...");  //give user time to analyse the lists  
//			}
		}
	if (ignoreAcquisitionsUseChannels) {
		uniqueAcquisitions = uniqueChannels;  // assumption iterate over acquisition now will iterate over channels
		useAcquisitionsBooleanLists = useChannelsBooleanLists;
	}
		
	for (currentTimeLine = 0; currentTimeLine < uniqueTimeLines.length; currentTimeLine++) {
		imageSequenceCounter = 0;
		for (currentAcquisition = 0; currentAcquisition < uniqueAcquisitions.length; currentAcquisition++) {
			if (useAcquisitionsBooleanLists[currentAcquisition] ) {  // only selected acquisitions / channels will be processed
				imageSequenceCounter++;  // only add one count if acquisition number is actually enabled and will be loaded 
				print("( " + (currentWellField+1) + " / " + uniqueWellFields.length + " ) open images with regex:", currentWell, currentField, uniqueTimeLines[currentTimeLine], uniqueAcquisitions[currentAcquisition]);
				regexString = "(.*_" + currentWell + "_.*" + currentField + ".*" + uniqueTimeLines[currentTimeLine] + ".*" + uniqueAcquisitions[currentAcquisition] + ".*)";
				print("regex:" + "(.*_" + currentWell + "_.*" + currentField + ".*" + uniqueTimeLines[currentTimeLine] + ".*" + uniqueAcquisitions[currentAcquisition] + ".*)");
				IJ.redirectErrorMessages();
				run("Image Sequence...", "open=[" + inputPath + "] file=" + regexString + " sort");
				if (nImages == imageSequenceCounter) { // see imageSequenceCounter above
					currentImage = getTitle();
					currentImage = currentImage + "_" + currentWell + "_" + currentField + "_" + uniqueTimeLines[currentTimeLine] + "_" + uniqueAcquisitions[currentAcquisition];
					rename(currentImage);
					if (acquisitonOption == availableAcquisitonOptions[2]) {   // "Merge as channels"	
						//print(imageSequenceCounter);
						mergeChannelsString = mergeChannelsString + "c" + channelToRGBArray[imageSequenceCounter - 1] + "=[" + currentImage + "] ";
						//print(mergeChannelsString);
						}
					print("opened ", nSlices, " images:", currentImage);
					} else {
					print("no images found");	// run Image Sequence silently failed...
					}

				//set contrast
				if (make8bit) {
					setMinAndMax(contrastValueArray[currentAcquisition * 2], contrastValueArray[currentAcquisition * 2 + 1]);
					run("8-bit");
					}

				if (acquisitonOption == availableAcquisitonOptions[0]) {   // "Keep separate files"	
					if (saveTif) {
						saveAs("Tiff", outputPath + currentImage + ".tif");
						print("saved", outputPath + currentImage + ".tif");
						}
					if (saveAvi) {
						run("AVI... ", "compression=" + aviCompression + " frame=" + framesPerSec + " save=" + outputPath + currentImage + ".avi");
						print("saved", outputPath + currentImage + ".avi");
						}
					close();
					imageSequenceCounter--; // image is processed and closed, therefore open image is again zero	
					}
				} //end if use acquisition / channel
			}  //end for acquistitions

		if (acquisitonOption == availableAcquisitonOptions[1]) {   // "Concatenate as series"	
			if (nImages > 1) {
				run("Concatenate...", "all_open title=Movie");
				currentImage = currentImage + "_concatenated";
				}
			}

		if (acquisitonOption == availableAcquisitonOptions[2]) {   // "Merge as channels"	
			if (nImages > 1) {
				run("Merge Channels...", mergeChannelsString + "create");  //"c1=Newfolder_C03_F001_A01 c2=Newfolder_C03_F001_A02 create");
				currentImage = currentImage + "_allChannels";
				}
			}
	
		//Save the image file
		if (nImages > 0) { //check if regex was sucessful and images could be opened
			if (saveTif) {
				saveAs("Tiff", outputPath + currentImage + ".tif");
				print("saved", outputPath + currentImage + ".tif");
				}
			if (saveAvi) {
				run("AVI... ", "compression=" + aviCompression + " frame=" + framesPerSec + " save=" + outputPath + currentImage + ".avi");
				print("saved", outputPath + currentImage + ".avi");
				}
			close();
			}
		}
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
Dialog.addCheckbox("Display the file lists?", displayFileList);	//if check file lists will be displayed
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
print(returnedFieldList.length + " field(s) found."); 
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
print(returnedWellFieldList.length + " well field(s) found."); 
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
print(returnedWellList.length + " well(s) found."); 
Array.sort(returnedWellList);
if (displayList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}

//function returnes the unique channels (e.g. C01) of an array of CV7000 files
//example: myUniqueChannels = getUniqueChannelListCV7000(myList, true);
function getUniqueChannelListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No channels found!");
	return newArray(0);
	}
currentChannel = substring(inputArray[0],lastIndexOf(inputArray[0],".tif")-3,lastIndexOf(inputArray[0],".tif"));   //first channel found
returnedChannelList = Array.concat(currentChannel);     //this list stores all unique channels found and is returned at the end of the function
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

//function returnes the unique acquisition numbers of an array of CV7000 files
//example: myUniqueAcquisitions = getUniqueAcquisitionListCV7000(myList, true);
function getUniqueAcquisitionListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No acquisition number found!");
	return newArray(0);
	}
currentAcquisition = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+13,lastIndexOf(inputArray[0],"_T00")+16);   //first acquisition found
returnedAcquisitionList = Array.concat(currentAcquisition);     //this list stores all unique aquisitions found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned aquisition list
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
print(returnedAcquisitionList.length + " acquisition number(s) found."); 
Array.sort(returnedAcquisitionList);
if (displayList) {Array.show("List of " + returnedAcquisitionList.length + " unique acquisition numbers", returnedAcquisitionList);}	
return returnedAcquisitionList;
}

//function returnes the unique time line numbers of an array of CV7000 files
//example: myUniqueTimeLines = getUniqueTimeLineListCV7000(myList, true);
function getUniqueTimeLineListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No time line number found!");
	return newArray(0);
	}
currentTimeLine = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+10,lastIndexOf(inputArray[0],"_T00")+13);   //first time line found
returnedTimeLineList = Array.concat(currentTimeLine);     //this list stores all unique time lines found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned time line list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedTimeLineList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentTimeLine = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")+10,lastIndexOf(inputArray[i],"_T00")+13);
		if(returnedTimeLineList[j] == currentTimeLine) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedTimeLineList = Array.concat(returnedTimeLineList, currentTimeLine);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedTimeLineList.length + " time line number(s) found."); 
Array.sort(returnedTimeLineList);
if (displayList) {Array.show("List of " + returnedTimeLineList.length + " unique time line numbers", returnedTimeLineList);}	
return returnedTimeLineList;
}

//function returnes the unique time line acquisitions of an array of CV7000 files
//example: myUniqueTimeLineAcquisitions = getUniqueTimeLineAcquisitionListCV7000(myList, true);
function getUniqueTimeLineAcquisitionListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No time line acquisition found!");
	return newArray(0);
	}
currentTimeLineAcquisition = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+10,lastIndexOf(inputArray[0],"_T00")+16);   //first time line acquisition found
returnedTimeLineAcquisitionList = Array.concat(currentTimeLineAcquisition);     //this list stores all unique time line acquisitions found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned time line aquisition list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedTimeLineAcquisitionList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentTimeLineAcquisition = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")+10,lastIndexOf(inputArray[i],"_T00")+16);
		if(returnedTimeLineAcquisitionList[j] == currentTimeLineAcquisition) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedTimeLineAcquisitionList = Array.concat(returnedTimeLineAcquisitionList, currentTimeLineAcquisition);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedTimeLineAcquisitionList.length + " time line acquisition(s) found."); 
Array.sort(returnedTimeLineAcquisitionList);
if (displayList) {Array.show("List of " + returnedTimeLineAcquisitionList.length + " unique time line acquisitions", returnedTimeLineAcquisitionList);}	
return returnedTimeLineAcquisitionList;
}
