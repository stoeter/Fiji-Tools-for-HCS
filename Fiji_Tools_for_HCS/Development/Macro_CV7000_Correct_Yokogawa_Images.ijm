//Correct-CV7000-Images
macroName = "Correct-CV7000-Images";
macroShortDescription = "This macro corrects CV7000 images for uneven illumination and geometric shifts.";
macroDescription = "This macro reads single .tif images from CV7000." +
	"<br>Correction files for uneven illumination and for geometric shift must be generated before." +
	"<br>The algorithm uses an affine transfomation to correct the channels.";
macroRelease = "first release 00-02-2015 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
//var inputPath = "/Users/stoeter/Desktop/CV7000&fish/";
//var outputPath = "/Users/stoeter/Desktop/CV7000&fish/output/"; 
var inputPath = "T:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\141111-BeadStacks-1_20141111_134223_raw\\AssayPlate_PerkinElmer_CellCarrier-384\\";
var inputPath = "T:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\141110-BeadStacks_20141110_192031_raw\\GreinerGlassPlate_GSP_500nm_beads\\";
var inputPathTransformMatrix = "T:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\analysis\\TestDataSetsForRegistration\\TransformationMatrix_testTransformations\\";
var inputPathIlluminationImages = "T:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\analysis\\TestDataSetsForRegistration\\141111-BeadStacks-1_20141111_134223_raw\\";
var outputPath = "T:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\analysis\\output_20150205\\"; 
var outputPath = "T:\\microscopy+imageanalysis\\CellVoyager_CV7000\\BeadStackTests_2014_11\\analysis\\output_20151229_GSP\\"; 
//var localTempPath = getDirectory("temp") + "FijiTemp" + File.separator;
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
inputPathTransformMatrix = getDirectory("Choose folder with transformation matrix");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";\ninputPathTransformMatrix = \"" + inputPathTransformMatrix + "\";";
print(printPaths);
//print("temp folder:", localTempPath);
//if(!File.exists(localTempPath)) File.makeDirectory(localTempPath);
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
var filterStrings = newArray("CellCarrier","Z11C","");				        	//pre-definition of strings to filter
var filterStrings = newArray("","","");				        	//pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");  //dont change this
var filterTerms = newArray("no filtering", "no filtering", "no filtering");	//pre-definition of filter types 
var displayFileList = false;

setDialogImageFileFilter();   //get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files without subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);			 //filter for extension
fileList = getFilteredFileList(fileList, displayFileList);    //filter for strings
channelList = getUniqueChannelListCV7000(fileList, displayFileList);//list of channels to process

print("===== checking transformation matirx files.... =====");
matrixList = getFileListSubfolder(inputPathTransformMatrix, displayFileList);  //read all files without subfolders
matrixList = getFileType(matrixList,".txt", displayFileList);			 //filter for extension
print(matrixList.length, "matrix files found.");

//waitForUser("Do you really want to open " + fileList.length + " files?" + "\n\n" + "Otherwise press 'ESC' and check image list and filter text!");
print("===== correcting images.... =====");
	//setBatchMode(batchMode);
for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {
	//get all images for one channel
	currentFileList = getFilteredList(fileList, channelList[currentChannel], false);
	//load and print matrix file for log window
	print("correcting " + currentFileList.length + " files for channel " + channelList[currentChannel]);
	print("using transformation matrix" + matrixList[currentChannel]);
	matrixAsText = File.openAsString(matrixList[currentChannel]);
	print(matrixAsText);
	matrixAsText = split(matrixAsText,"\n");
	//go through all files in current file list
	for (currentFile = 0; currentFile < currentFileList.length; currentFile++) {
		if (endsWith(currentFileList[currentFile],".tif")) {   //check if it is right file and handle error on open()
			showProgress(currentFile / currentFileList.length);
			showStatus("processing" + currentFileList[currentFile]);
	   	    IJ.redirectErrorMessages();
	   	    open(currentFileList[currentFile]);
	   	    imageName = getTitle();
			//correct image with matrix for this channel
			run("TransformJ Affine", "matrix=" + matrixList[currentChannel] + " interpolation=[Linear] background=0.0");	
			selectWindow(imageName);
			close();
			selectWindow(imageName + " affined");
			saveAs("Tiff", outputPath + imageName);
			print("saved corrected", imageName);  
			close();
			//waitForUser("wait");
			}
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
//function get all files from folders and subfolders
function getFileListSubfolder(inputPathFunction, displayFileList) {
fileList = getFileList(inputPathFunction);  //read file list
Array.sort(fileList);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileList.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileList[i], "/"))) fileList[i] = replace(fileList[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileList[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPathFunction + fileList[i]);
		returnedFileList = Array.concat(returnedFileList, returnedFileListTemp);
		} else {  									//if it is a file
		returnedFileList = Array.concat(returnedFileList, inputPathFunction + fileList[i]);
		//print(i, inputPath + fileList[i]);
		}
	}
if(inputPathFunction == inputPath) { //if local variable is equal to global path variable = if path is folder and NOT subfolder
	print(returnedFileList.length + " files found in selected folder and subfolders."); 	
	if (displayFileList) {Array.show("All files - all",returnedFileList);} 	
	}
return returnedFileList;
}

//function get all folders from a folder
function getFolderList(inputPath, displayFileList) {
fileListFunction = getFileList(inputPath);  //read file list
Array.sort(fileList);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileList.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileList[i], "/"))) fileList[i] = replace(fileList[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileList[i], File.separator))  returnedFileList = Array.concat(returnedFileList,fileList[i]);//if it is a folder
	}
print(returnedFileList.length + " folders were found."); 
if (displayFileList) {Array.show("Found folders", returnedFileList);}	
return returnedFileList;
}

//function finds all files with certain extension
function getFileType(fileListFunction, fileExtension, displayFileList) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
if(lengthOf(fileExtension) > 0) {
	for (i = 0; i < fileListFunction.length; i++) {
		if (endsWith(fileListFunction[i],fileExtension)) returnedFileList = Array.concat(returnedFileList,fileListFunction[i]);
		}
	print(returnedFileList.length + " files found with extension " + fileExtension + ".");
	if (displayFileList) {Array.show("All files - filtered for " + fileExtension, returnedFileList);} 
	} else {
	returnedFileList = fileListFunction;	
	}
return returnedFileList;
}

var filterStrings = newArray("","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("no filtering", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
//function filter a file list for a certain string
function getFilteredFileList(fileListFunction, displayFileList) {
skippedFilter = 0;	
for (i = 0; i < filterStrings.length; i++) {
	if (filterTerms[i] != availableFilterTerms[0]) {
		returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
		for (j = 0; j < fileList.length; j++) {
			if (filterTerms[i] == "include" && indexOf(fileList[j],filterStrings[i]) != -1) returnedFileList = Array.concat(returnedFileList,fileListFunction[j]);
			if (filterTerms[i] == "exclude" && indexOf(fileList[j],filterStrings[i]) <= 0) returnedFileList = Array.concat(returnedFileList,fileListFunction[j]);
			}
		print(returnedFileList.length + " files found after filter: " + filterTerms[i] + " text " + filterStrings[i] + "."); 
		if (displayFileList) {Array.show("List of files - after filtering for " + filterStrings[i], returnedFileList);}
		fileListFunction = returnedFileList;
		} else skippedFilter++;
	} 
if (skippedFilter == filterStrings.length) returnedFileList = fileListFunction;	//if no filter condition is selected
return returnedFileList;
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

//function filter a list for a certain string (filter)
function getFilteredList(inputList, filterStringFunction, displayList) {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " items found after filtering: " + filterStringFunction); 
if (displayList) {Array.show("List after filtering for " + filterStringFunction, returnedList);}
return returnedList;
}

//function returnes the unique values of an array
function getUniqueArrayValues(inputArray, displayList) {
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
Array.sort(outputArray);
if (displayList) {Array.show("List of " + outputArray.length + " unique values", outputArray);}	
return outputArray;
}

//function returnes the unique wells of an array of CV7000 files
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
function getUniqueWellFieldListCV7000(inputArray, displayList) {
currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00")+10);   //first well field found
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
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
print(returnedWellFieldList.length + " wells fiels found."); 
Array.sort(returnedWellFieldList);
if (displayList) {Array.show("List of " + returnedWellFieldList.length + " unique well fields", returnedWellFieldList);}	
return returnedWellFieldList;
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
print(returnedChannelList.length + " channels found."); 
Array.sort(returnedChannelList);
if (displayList) {Array.show("List of " + returnedChannelList.length + " unique channels", returnedChannelList);}	
return returnedChannelList;
}

////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////

