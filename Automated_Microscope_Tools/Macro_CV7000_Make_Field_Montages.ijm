//CV7000-Make-Field-Montages
macroName = "CV7000-Make-Field-Montages";
macroShortDescription = "This macro opens CV7000 images of a well-channel and does a montage of the fields.";
macroDescription = "This macro reads single CV7000 images of a well as .tif ." +
	"<br>The chosen folder will be searched for images including subfolders." +
	"<br>All images of a unique well and channel are opened and used for a montage." +
	"<br>Montage settings (rows, columns) and file tag can be adjusted." +
	"<br>Montage order of images will be alphanumerical (e.g. field position) and row-wise." +
	"<br>There is an option to run a channel-specific background subtraction before/after the montage." +
	"<br>All z-projection methods selectable. Pixel size can be automatically corrected.";
macroRelease = "fifth release 10-07-2023";
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
print(macroName, "(" + macroRelease + ")", "\nStart:",year + "-" + month + "-" + dayOfMonth + ", h" + hour + "-m" + minute + "-s" + second);
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
//inputPath = "H:\\Anna\\220308_Agg\\yokogawa\\002AD220308a-Agg-T000_20220308_155054\\002AD220308a-Agg-T000\\";
//outputPath = "H:\\Anna\\220308_Agg\\yokogawa\\FIJI-processing_MS\\test_results\\";

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
batchMode = true;
availableMontageFileTags = newArray("000", "all", "put my own tag");
defaultFilterStrings = newArray("DC_sCMOS #","SC_BP","");
print("Files containing these strings will be automatically filtered out:");
Array.print(defaultFilterStrings);
bkgCorrection = false;
doPixelSizeCorrection = true;

//set array variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("no filtering", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();

print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

displayMetaData = false;
Dialog.create("Find meta data");
Dialog.addCheckbox("Display unique values of meta data:", displayMetaData);	
Dialog.show();
displayMetaData = Dialog.getCheckbox();

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

wellList = getUniqueWellListCV7000(fileList, displayMetaData);
wellFieldList = getUniqueWellFieldListCV7000(fileList, displayMetaData);
fieldList = getUniqueFieldListCV7000(fileList, displayMetaData);
channelList = getUniqueChannelListCV7000(fileList, displayMetaData);
zplaneList = getUniqueZplaneListCV7000(fileList, displayMetaData);
print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n", zplaneList.length, "z-planes found\n");
stackSize = fileList.length / wellList.length / channelList.length / zplaneList.length;
print("Assuming wells with ", stackSize, "fields. Please check if this is correct!");
if(displayFileList || displayMetaData) waitForUser("Take a look at the list windows...");  //give user time to analyse the lists  

//set montage type
montageColumn = Math.ceil(stackSize / 2);
montageRow = Math.floor(stackSize / 2);
Dialog.create("Set montage type");
Dialog.addNumber("Montage columns:", montageColumn);
Dialog.addNumber("Montage rows:", montageRow);
Dialog.addChoice("Montage file tag:", availableMontageFileTags);
Dialog.addCheckbox("Background correction?", bkgCorrection);	//if checked background subtration will be done before and after the montage
Dialog.addCheckbox("Automatically correct pixel size?", doPixelSizeCorrection);	//if checked .mrf file will be read and pixel size will be corrected
Dialog.addCheckbox("Set batch mode (hide images)?", batchMode);	//if checked no images will be displayed
Dialog.show();
montageColumn = Dialog.getNumber();
montageRow = Dialog.getNumber();
montageFileTag = Dialog.getChoice();
bkgCorrection = Dialog.getCheckbox();
doPixelSizeCorrection = Dialog.getCheckbox();
batchMode = Dialog.getCheckbox();

if (montageFileTag == "put my own tag") { // user defined file tag
	Dialog.create("Set montage tag");
	Dialog.addString("Montage file tag:", availableMontageFileTags[1]);
	Dialog.show();
	montageFileTag = Dialog.getString();
	}
print("Montage: columns:", montageColumn, ", rows:", montageRow);

// set per default that no background correction is done for all channels
correctionType = newArray(channelList.length);
for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) correctionType[currentChannel] = "none";  

if (bkgCorrection) { // set specify background correction
	Dialog.create("Set background correction");
	Dialog.addMessage("Choose:\n 'none' for no correction,\n 'dark' for fluorecence channels,\n 'light' for bright field channels.");
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {
		defaultSetting = "none";
		if (channelList[currentChannel] == "C05") defaultSetting = "light";
		Dialog.addChoice("Background correction for channel: " + channelList[currentChannel], newArray("none", "dark", "light"), defaultSetting);
		}
	Dialog.addNumber("Rolling ball radius:", 150);	
	Dialog.show();
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {
		correctionType[currentChannel] = Dialog.getChoice();
		print("Channel -", channelList[currentChannel], ":", correctionType[currentChannel]);
		}
	rollingBallRadius = Dialog.getNumber();	
	print("Rolling ball radius:", rollingBallRadius);
	}

if (doPixelSizeCorrection) pixelSizeMrf = readMRFfile(inputPath);  // get pixel size from .mrf file

print("===== starting processing.... =====");
setBatchMode(batchMode);

//go through all files
for (currentWell = 0; currentWell < wellList.length; currentWell++) {   // well by well
	print("well (" + (currentWell + 1) + "/" + wellList.length + ") ...");  //to log window
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel per well
		lightBackground = "";   // lightBackground is alwasy "" unless it is bright field, then it is " light"
		if (correctionType[currentChannel] == "light") lightBackground = " light";
		for (currentZplane = 0; currentZplane < zplaneList.length; currentZplane++) {  // z-plane by z-plane per channel and well

            //define new filters and filter file list for currentWell and currentChannel
            filterStrings = newArray("_" + wellList[currentWell] + "_",channelList[currentChannel] + ".tif",zplaneList[currentZplane]);      //pre-definition of strings to filter, add "_" because well strings e.g. A03, L01, C02 can be in file name at other places, e.g ..._A06_T0001F001L01A03Z01C02.tif and ".tif" to excluse well C02 instead of channel C02
            filterTerms = newArray("include", "include", "include");  //pre-definition of filter types 
            wellChannelFileList = getFilteredFileList(fileList, false, false);
		
            if(wellChannelFileList.length > montageRow * montageColumn) {
                print("Error: too may files in file list for well " + wellList[currentWell] + ", channel: " + channelList[currentChannel] + ", z-plane: " + zplaneList[currentZplane]);
                Array.print(wellChannelFileList);
                break;
            }
            //now open all files (wellChannelFileList) that belong to one wellField in one channel
            for (currentFile = 0; currentFile < wellChannelFileList.length; currentFile++) {
                //image sequence & regEx would be possible, but it seems to be slow: run("Image Sequence...", "open=Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\ file=(_B03_.*C01) sort");
                IJ.redirectErrorMessages();
                if (File.exists(wellChannelFileList[currentFile])) {
                    open(wellChannelFileList[currentFile]);
                    currentImage = getTitle();
                    print("opened (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
                    if (doPixelSizeCorrection) correctPixelSize(pixelSizeMrf);   // do pixel size / unit correction
                    } else {
                    print("file not found (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
                    }
                showProgress(currentFile / wellChannelFileList.length);
                showStatus("processing" + fileList[currentFile]);
                } //end for all images per channel	
            //waitForUser("done");	
            if (nImages > 1) {
                run("Images to Stack", "name=Stack title=[] use");
                if (correctionType[currentChannel] != "none") {  // lightBackground is alwasy "" unless it is bright field, then it is " light"
                	print("subtracting background with rolling ball = " + rollingBallRadius + " and type " + correctionType[currentChannel] + ":" + lightBackground);
                	run("Subtract Background...", "rolling=" + rollingBallRadius + lightBackground + " stack");  
                	}
                run("Make Montage...", "columns=" + montageColumn + " rows=" + montageRow + " scale=1");
                if (correctionType[currentChannel] != "none") run("Subtract Background...", "rolling=" + rollingBallRadius + lightBackground);
                outputFileName = substring(currentImage,0,lengthOf(currentImage)-19) + montageFileTag + substring(currentImage,lengthOf(currentImage)-16,lengthOf(currentImage));
                saveAs("Tiff", outputPath + outputFileName);
                close();  // montage
                print("saved montage as " + outputPath + outputFileName);  //to log window
                selectWindow("Stack"); //stack
                close();
                } else {  //end if images are open
                run("Close All");
                }
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
Dialog.addCheckbox("Display the file lists?", displayFileList);	//if check file lists will be displayed
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
if (lastIndexOf(inputArray[0],"_T0") > 0) { //check first well
	currentWell = substring(inputArray[0],lastIndexOf(inputArray[0],"_T0")-3,lastIndexOf(inputArray[0],"_T0"));   //first well found
	} else {
	print("no well found in path:", inputArray[i]);	
	exit("No well information found in file name. Please double-check the file filtering...");
	}	
returnedWellList = newArray(currentWell);     //this list stores all unique wells found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned well list
	valueUnique = true;						//as long as value was not found in array of unique values
	if (lastIndexOf(inputArray[i],"_T0") > 0) {  // if CV7000 file names are recognized
		while (valueUnique && (returnedWellList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
			currentWell = substring(inputArray[i],lastIndexOf(inputArray[i],"_T0")-3,lastIndexOf(inputArray[i],"_T0"));
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
if (lastIndexOf(inputArray[0],"_T0") > 0) { //check first well field
	currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T0")-3,lastIndexOf(inputArray[0],"_T0")+10);   //first well field found
	} else {
	print("no well found in path:", inputArray[i]);	
	exit("No well field information found in file name. Please double-check the file filtering...");
	}
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
//print("start:", currentWellField, returnedWellFieldList.length);
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	if (lastIndexOf(inputArray[i],"_T0") > 0) {  // if CV7000 file names are recognized
		while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
			currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T0")-3,lastIndexOf(inputArray[i],"_T0")+10);
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
currentField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T0")+6,lastIndexOf(inputArray[0],"_T0")+10);   //first field found
returnedFieldList = newArray(currentField);     //this list stores all unique fields found and is returned at the end of the function
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentField = substring(inputArray[i], lastIndexOf(inputArray[i],"_T0")+6, lastIndexOf(inputArray[i],"_T0")+10);
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

//function returnes the unique z-planes (e.g. Z01) of an array of CV7000 files
//example: myUniqueZplanes = getUniqueZplaneListCV7000(myList, true);
function getUniqueZplaneListCV7000(inputArray, displayList) {
currentZplane = substring(inputArray[0],lastIndexOf(inputArray[0],".tif")-6,lastIndexOf(inputArray[0],".tif")-3);   //first Zplane found
returnedZplaneList = newArray(currentZplane);     //this list stores all unique Zplanes found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned channel list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedZplaneList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentZplane = substring(inputArray[i],lastIndexOf(inputArray[i],".tif")-6,lastIndexOf(inputArray[i],".tif")-3);
		if(returnedZplaneList[j] == currentZplane) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedZplaneList = Array.concat(returnedZplaneList, currentZplane);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedZplaneList.length + " zplane(s) found."); 
Array.sort(returnedZplaneList);
if (displayList) {Array.show("List of " + returnedZplaneList.length + " unique z-planes", returnedZplaneList);}	
return returnedZplaneList;
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

//function detemins the current pixel size and unit of an image and corrects it this the given parameter
// if pixel size paramweter is <= 0 no correction of pixel size will be done
//example: correctPixelSize(pixelSizeMrf)
function correctPixelSize(pixelSizeMrf) { 
if (pixelSizeMrf <= 0) return;
getPixelSize(pixelUnit, pixelWidth, pixelHeight);
if (pixelUnit == "inches") {  // default, but wrong in CV7000 images
	print("Pixel units:", pixelUnit, "; pixel size and unit will be corrected.");
	Stack.setXUnit("um");
	Stack.setYUnit("um");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=" + pixelSizeMrf + " pixel_height=" + pixelSizeMrf + " voxel_depth=1");
	} else {
	print("Pixel size was already adapted. No correction will be done. Pixel units and sizes are:", pixelUnit, pixelWidth, pixelHeight);	
	}
}

//function reads the CV7000 .mrf file and detemins the pixel size
//example: pixelSizeMrf = readMRFfile(inputPath)
function readMRFfile(inputPath) { 
mrfFilePath = inputPath + "MeasurementDetail.mrf";
pixelSizeMrf = 0;  // by default initialize value that is given back by this function
doPixelSizeCorrection = true;  // function variable that checks it pixel sizes are unique in .mrf, otherwise funtion will return -1 
// open .mrf file and split into line array  
if (!File.exists(mrfFilePath)) {
	print("Could not find .mrf file:", mrfFilePath, "\nPixel size could not be determined and is not automatically corrected!");
	} else {
	return -1;  // if no .mrf file found, then return -1 as pixel size
	mrfFile = File.openAsString(mrfFilePath);
	lines = split(mrfFile,"\n");
	print("Reading .mrf file... length:", mrfFile.length, "; lines:", lines.length);
	// go through each line and fine dimension for each channel
	for (line = 0; line < lines.length; line++) {
    	if (matches(lines[line], "(.*Dimension.*)") ) {
    		splitLines = split(lines[line], "\"");
    		channelMrf = splitLines[1];
	    	if (pixelSizeMrf == 0) {     // on first iteration
 		   		pixelSizeMrf = splitLines[3];
    			} else {
    			if (pixelSizeMrf != splitLines[3] && doPixelSizeCorrection) {     // if multiple pixel sizes or no correction 
    				print("Multiple pixel sizes in .mrf file. No correction of pixel sizes will be applied, because this could lead to mistakes...");
    				doPixelSizeCorrection = false;
    				pixelSizeMrf = splitLines[3];
    				} else {                                                 // if all is normal
    				pixelSizeMrf = splitLines[3];
    				}
    			}
    		print("Channel", channelMrf, "has pixel size of", pixelSizeMrf, "um/px");
    		}  // line matches
		}  // for each line
	if (doPixelSizeCorrection == false) {
		return -1;  // if multiple pixel sizes in .mrf, then return -1 as pixel size
		} else {
		return pixelSizeMrf;	
		}
	}  // if exists
}  // function
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////










