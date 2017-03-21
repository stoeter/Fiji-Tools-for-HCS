//Cell-Classifier
macroName = "Cell-Classifier";
macroShortDescription = "With this Macro you can speed up clessification of cell on many images.";
macroDescription = "This macro helps to classify cells or objects." +
	"<br>Images will be opened in groups as stack and user can count object in the defined classes." + 
	"<br>- Select input folder" +
	"<br>- Select ouput folder for saving files (class model, classification results)" + 
	"<br>- Follow the instructions" + 
	"<br>- HINT: user + and - keys to zoom in and out, use < and > keys to move stack slices forth and back.";
macroRelease = "first release 17-03-2017 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
var fileExtension = ".jpg";                                                  //pre-definition of extension
var filterStrings = newArray("_T0001","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("include", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();
print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings

groupingImagesArray = newArray("per well", "per field", "per well-field", "batch of images");

Dialog.create("Setting for analysis");
Dialog.addMessage("Define the grouping of images:");
Dialog.addChoice("Load one group of", groupingImagesArray, groupingImagesArray[0]);
Dialog.addCheckbox("Display unique values for group?", false);
Dialog.addNumber("How many batches (there are " + fileList.length + " files)?", 10);
//Dialog.addCheckbox(" - as stack as .tif?", true);
//Dialog.addMessage("");
//Dialog.addCheckbox("Save ROI for reanalysis?", true);
Dialog.show(); 
groupingImages = Dialog.getChoice();
displayGroup = Dialog.getCheckbox();
numberOfBatches = Dialog.getNumber();
//saveTif = Dialog.getCheckbox();
//saveROI = Dialog.getCheckbox();

if (groupingImages == groupingImagesArray[0]) {
	groupList = getUniqueWellListCV7000(fileList, displayGroup);
	print("Number of unique wells:", groupList.length);
	}
if (groupingImages == groupingImagesArray[1]) {
	groupList = getUniqueFieldListCV7000(fileList, displayGroup);
	print("Number of unique fields:", groupList.length);
	}
if (groupingImages == groupingImagesArray[2]) {
	groupList = getUniqueWellFieldListCV7000(fileList, displayGroup);
	print("Number of unique well-fields:", groupList.length);
	}
if (groupingImages == groupingImagesArray[3]) {
	groupList = Array.getSequence(numberOfBatches);
	filesPerBatch = floor(fileList.length / numberOfBatches) + 1;
	print("Running " + numberOfBatches + " batches with " + filesPerBatch + " files per batch.");
	}

textWindowName = "Interactive Instructions";
textWindow = "["+textWindowName+"]";
if (isOpen(textWindowName)) 
	print(textWindow, "\\Update:"); // clears the window
	else
	run("Text Window...", "name=" + textWindow + " width=72 height=10");
print(textWindow, "See follow macro instructions\nand see instructions in Log window...");	
	
/*if (true) {//isOpen("Cell Counter")  //this doesnt seem to work
	selectWindow("Cell Counter");
	print("cell counter open");
	run("Close");
	IJ.closeWindow("Cell Counter");
	//close("Cell Counter");
	}*/
  
for (currentGroup = 0; currentGroup < groupList.length; currentGroup++) {

	if (groupingImages == groupingImagesArray[3]) { //  = batch of images
		groupFileList = Array.slice(fileList, currentGroup * filesPerBatch, currentGroup * filesPerBatch + filesPerBatch);
		print("opening file batch:", currentGroup + 1, "- set:", currentGroup * filesPerBatch + 1, currentGroup * filesPerBatch + filesPerBatch);
		} else {
		groupFileList = getFilteredList(fileList, groupList[currentGroup], false);    //filter for strings of unique group
		}

	//write names of opened files into text file
	groupFileListTextFileName = "FileListGroup_" + groupList[currentGroup] + ".txt";  // file name of text file (groupFileListTextFile) which stores image paths
	print("save list of opened files in text file: " + groupFileListTextFileName);
	groupFileListTextFile = File.open(outputPath + groupFileListTextFileName);
	print(groupFileListTextFile, "Group\tSlice\tFile name"); //write header in FileListGroup text file

	//setBatchMode(true);
	for (currentGroupFile = 0; currentGroupFile < groupFileList.length; currentGroupFile++) {
		// open files one after the other...
		IJ.redirectErrorMessages();
		open(groupFileList[currentGroupFile]);
		currentImage = getTitle();
		print("opened image", currentImage);
		print(groupFileListTextFile, groupList[currentGroup] + "\t" + (currentGroupFile+1) + "\t" + groupFileList[currentGroupFile]); //store FileListGroup as text file
		//showProgress(currentGroupFile / groupFileList.length);
		}
	
	File.close(groupFileListTextFile); //save text file with file names
	run("Images to Stack");
	rename("ImageGroup_" + groupList[currentGroup]);  //now ready for Cell Counter

	if (currentGroup == 0) {
		run("Cell Counter");
		waitForUser("Please make sure only one 'Cell Counter' windows is open...");
		printInstructionsToLog();  // see function below... 
		waitForUser("- press [Initialize]\n- set up the classes in [Counter]\n- see details & instructions in the [Log] window Chapter 1 ...");
		} else {
		waitForUser("- press [Initialize]");	
		}
		
	waitForUser("- do your classifications...\n- see details & instructions in the [Log] window Chapter 2 ...\n- when you are done press 'ok'");
	currentImageStack = getTitle();
	print(textWindow, "\\Update:"); // clears the window
	print(textWindow, "\n" + currentImageStack + ".xml\n" + "- use this file name with copy/paste" + "\n" + "- press [Save markers] to save the classification points");
	print(textWindow, "\n\n" + currentImageStack + ".txt\n" + "- use this file name with copy/paste" + "\n" + "- press [Measure] to save the classification results");
	waitForUser("Follow instructions in window 'Interactive Instructions'\n- ...save markers\n- ...save measurements\n- see details & instructions in the [Log] window Chapter 3 ...");
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber +".txt");
	close(currentImageStack);
	}
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 

/////////////////////////////////////////////////////////////////////////////////////////////
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////

//prit macro instructions to log window
function printInstructionsToLog() {
print("\nInstructions of running the Cell Counter:");
print("-----------------------------------------");
print("- press [Initialize] => you need to do this for each loaded image group...");
print("=> before you start classifing think about the number of classes needed and clear class names");
print("=> dont use more than 8 classes, macro will work but Cell Counter has bugs / limitations");
print("\nChapter 1: Set up the Classes / [Counters]:");
print("- select a class (e.g. Type 1)");
print("- click [Rename] and type in a class name");
print("   - do this for all classes you want to have...");
print("   - you can [Add] and [Remove] classes (try to uses no more than 8 classes)");
print("   - document elsewhere class number & name (e.g. .txt), because the class name will not be saved anywhere!");	
print("   - once the Cell Counter is closed your class names will be lost... -> make new with [Rename]!");	
print("   - use [Options] to set the color for each class (also wont be saved in .xml!)");		
print("\nChapter 2: Classify your objects:");
print("- select a class (e.g. Class normal)");
print("- right click on image into center of object => class number appears");
print("- classify all objects you want in all images...");	
print("- delete the last click by pressing [Delete]");
print("- delete any class point by checking [Delete Mode] => dont forget to uncheck afterwards!");
print("   - HINT: user + and - keys to zoom in and out");
print("   - HINT: use < and > keys or mouse wheel to move stack slices forth and back");
print("\nChapter 3: Save your classification:");
print("- follow instructions in the window 'Interactive Instructions' => you can copy/paste from this window!");		
print("- copy .xml file name from that window (apple/CTRL + C)");
print("- click [Save Markers] and paste .xml file name");
print("- copy .txt file name from that window (apple/CTRL + C)");
print("- click [Measurement], select 'Result' window and save results using pasted .txt file name");
print("-----------------------------------------");
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

//function filters a list for a certain string (filter)
//example: myList = getFilteredList(myList, "myText", true);
function getFilteredList(inputList, filterStringFunction, displayList) {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " file(s) found after filtering: " + filterStringFunction); 
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
	print(returnedFileList.length + " file(s) found in selected folder and subfolders."); 	
	if (displayList) {Array.show("All files - all", returnedFileList);} 	
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

