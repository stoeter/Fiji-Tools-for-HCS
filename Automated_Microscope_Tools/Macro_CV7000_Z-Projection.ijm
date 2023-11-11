//CV7000-Z-Projection
macroName = "CV7000-Z-Projection";
macroShortDescription = "This macro opens CV7000 images of a well-field-channel and does a z projection.";
macroDescription = "This macro reads single CV7000 images of a well as .tif ." +
	"<br>The chosen folder will be searched for images including subfolders." +
	"<br>Option to select several input folders for batch processing at end of GUI." +
	"<br>All images of a unique well, field and channel are opened and projected." +
	"<br>All z-projection methods selectable. Pixel size can be automatically corrected." +
	"<br>Projection and / or image stack files (to subfolder 'stack') can be saved (can handle stacks larger than 100 (e.g. Z100))." +
	"<br>Option to copy CV7000 meta data files to output folder.";
macroRelease = "1.9.1_231109";
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
availableProjectionTerms = newArray("Max Intensity", "Sum Slices", "Average Intensity", "Min Intensity", "Standard Deviation", "Median");
availableProjectionFileTags = newArray("00", "all", "max", "min", "avg", "put my own tag");
var defaultFilterStrings = newArray("DC_sCMOS #","SC_BP","");
print("Files containing these strings will be automatically filtered out:");
Array.print(defaultFilterStrings);
saveProjection = true;
saveStack = false;
doPixelSizeCorrection = true;
copyCV7000metadataFiles = false;
doMultipleFolders = false;
var zPlaneDigitProblem = 0;  // this will be only used and set to 1 if stack is saved and number of z planes are > 99, thereby 3-digits => e.g. Z100

//set array variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("no filtering", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 

setDialogImageFileFilter();
filterStringsUserGUI = filterStrings;                                        //store strings that user enterd in "backup variable" 
filterTermsUserGUI = filterTerms;                                            //store terms that user enterd in "backup variable" 

var CV7000metadataFileList = newArray(0);                                     //initialize - list of files (metadata forom CV7000) that will be copied to outoutPath

print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

displayMetaData = false;
Dialog.create("Find meta data of file names");
Dialog.addCheckbox("Display unique values of meta data:", displayMetaData);	
Dialog.show();
displayMetaData = Dialog.getCheckbox();

print("Processing file list...");

//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
//fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFileTypeAndCV7000metaDataFiles(fileList, fileExtension, displayFileList);   // new funtion to store the CV7000 meta data files in separate list (CV7000metadataFileList)
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings
if (fileList.length == 0) exit("No files to process");  

// these steps below are not neccessary anymore because this filtering is done in the getFileTypeAndCV7000metaDataFiles (filters out the CV7000 meta data files that are .tif)
//filterStrings = newArray("DC_sCMOS #","SC_BP","");
//filterTerms = newArray("exclude", "exclude", "no filtering"); 
print("removing correction files from file list containing text", defaultFilterStrings[0], defaultFilterStrings[1], defaultFilterStrings[2]);
//fileList = getFilteredFileList(fileList, false, false);
//if (fileList.length == 0) exit("No files to process");  

wellList = getUniqueWellListCV7000(fileList, displayMetaData);
wellFieldList = getUniqueWellFieldListCV7000(fileList, displayMetaData);
fieldList = getUniqueFieldListCV7000(fileList, displayMetaData);
channelList = getUniqueChannelListCV7000(fileList, displayMetaData);
print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n");
stackSize = fileList.length / wellFieldList.length / channelList.length;
print("Assuming stacks with ", stackSize, "planes. Please check if this is correct!");
if(displayFileList || displayMetaData) waitForUser("Take a look at the list windows...");  //give user time to analyse the lists  

//set projection type
Dialog.create("Set projection type");
Dialog.addChoice("Projection:", availableProjectionTerms);	//set number of images in one row
Dialog.addNumber("Lowest plane:", 1);
Dialog.addNumber("Highest plane:", stackSize);
Dialog.addChoice("Projection file tag:", availableProjectionFileTags);
Dialog.addCheckbox("Save Z-projection?", saveProjection);	// if checked images will be saved as projection
Dialog.addCheckbox("Save Z-stack in subfolder?", saveStack);	// if checked images will be saved as stack
Dialog.addCheckbox("Automatically correct pixel size?", doPixelSizeCorrection);	//if checked .mrf file will be read and pixel size will be corrected
Dialog.addCheckbox("Copy CV7000 meta data files?", copyCV7000metadataFiles);	//if checked meta date file from CV7000, such as .mrf, .mes, correction files etc., will be copied to output path
Dialog.addCheckbox("Set batch mode (hide images)?", batchMode);	//if checked no images will be displayed
Dialog.addCheckbox("Process multiple folders with same settings?", doMultipleFolders);	//if checked no images will be displayed
Dialog.show();
projectionType = Dialog.getChoice();
Zstart = Dialog.getNumber();
Zstop = Dialog.getNumber();
projectionFileTag = Dialog.getChoice();
saveProjection = Dialog.getCheckbox();
saveStack = Dialog.getCheckbox();
doPixelSizeCorrection = Dialog.getCheckbox();
copyCV7000metadataFiles = Dialog.getCheckbox();
batchMode = Dialog.getCheckbox();
doMultipleFolders = Dialog.getCheckbox();

if (projectionFileTag == "put my own tag") { // user defined file tag
	Dialog.create("Set projection tag");
	Dialog.addString("Projection file tag:", availableProjectionFileTags[1]);
	Dialog.show();
	projectionFileTag = Dialog.getString();
	}
print("Selected projection type:", projectionType, "starting from plane", Zstart, "until plane", Zstop);
print("Saving the Z-projection (0=false, 1=true):", saveProjection, "saving the stack:", saveStack, "copy CV700 meta data files:", copyCV7000metadataFiles, "using file tag:", projectionFileTag, "process multiple folders:", doMultipleFolders);

//define input folders: bring input paths info array format
inputPaths = newArray(inputPath);
if (doMultipleFolders) {
	print("\nPROCESSING MULTIPLE FOLDERS...");
	displayFileList = false;
	displayMetaData = false;
	addAnotherFolder = true;
	while (addAnotherFolder) {  // add folders to process until checkbox unchecked
		inputPaths[inputPaths.length] = getDirectory("Choose image folder... ");
		print("Folder added to process list:", inputPaths[inputPaths.length - 1]);
		Dialog.create("Process multiple folders?");
		Dialog.addCheckbox("Select another folder?", addAnotherFolder);	//if checked another interation of selection a folder is done
		Dialog.show();
		addAnotherFolder = Dialog.getCheckbox();
		} // end while
	}
print("In total", inputPaths.length, "folders will be processed...");

// start looping over all folders
for (currentFolder = 0; currentFolder < inputPaths.length; currentFolder++) { // folder by folder

    // if multiple folders are selected then make default output folder in input folder
    if (inputPaths.length > 1) {  
        print("\n================== starting processing a new folder... ====================");
        print("Preparation for folder #" + (currentFolder + 1) + ":", inputPaths[currentFolder]);  //to log window
        outputPath = substring(inputPaths[currentFolder], 0, lastIndexOf(inputPaths[currentFolder], File.separator)) + File.separator + "Zprojection" + File.separator;
        outputPath = inputPaths[currentFolder] + "Zprojection" + File.separator;
        File.makeDirectory(outputPath);
        print("New output folder -> made folder for projection files: " + outputPath);  //to log window
        }
        
    // if multiple folders are selected then from second iteration on the several lists need to be updated for next iteration, like fileList, CV7000metadataFileList, well/field/channelList, filterStrings/Terms(user/GUI variables)
    if (currentFolder > 0)  { // dont do on first iteration: from second iteration on, get file list from new folder
        print("Processing file list...");
        
        //get file list ALL
        fileList = getFileListSubfolder(inputPaths[currentFolder], displayFileList);  //read all files in subfolders
        CV7000metadataFileList = newArray(0); // reset the meta data file list
        fileList = getFileTypeAndCV7000metaDataFiles(fileList, fileExtension, displayFileList);   // new funtion to store the CV7000 meta data files in separate list (CV7000metadataFileList)
        filterStrings = filterStringsUserGUI;                              //restore user enterd strings from "backup variable" 
        filterTerms = filterTermsUserGUI;                                  //restore user enterd terms from "backup variable"
        fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings
        if (fileList.length == 0) exit("No files to process");  
        print("removing correction files from file list containing text", defaultFilterStrings[0], defaultFilterStrings[1], defaultFilterStrings[2]);
        wellList = getUniqueWellListCV7000(fileList, displayMetaData);
        wellFieldList = getUniqueWellFieldListCV7000(fileList, displayMetaData);
        fieldList = getUniqueFieldListCV7000(fileList, displayMetaData);
        channelList = getUniqueChannelListCV7000(fileList, displayMetaData);
        print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n");
        print("Calculated number of planed in stacks is ", fileList.length / wellFieldList.length / channelList.length);
        print("Using settings of first iteration (first selected folder)...");
        print("Selected projection type:", projectionType, "starting from plane", Zstart, "until plane", Zstop);
        print("Saving the Z-projection (0=false, 1=true):", saveProjection, "saving the stack:", saveStack, "copy CV700 meta data files:", copyCV7000metadataFiles, "using file tag:", projectionFileTag, "process multiple folders:", doMultipleFolders);
        saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
        }  // end processing of multiple folders from second folder on

    if (saveStack) {
        File.makeDirectory(outputPath + "stack");
        print("made folder for saving stack files: " + outputPath + "stack" + File.separator);  //to log window
        }	
    if (doPixelSizeCorrection) pixelSizeMrf = readMRFfile(inputPaths[currentFolder]);  // get pixel size from .mrf file

    print("\n===== starting processing files... =====");
    setBatchMode(batchMode);
    if (doMultipleFolders) print("input path is:", inputPaths[currentFolder]);
    if (copyCV7000metadataFiles) copyFiles(CV7000metadataFileList, outputPath);

    //go through all files
    for (currentWellField = 0; currentWellField < wellFieldList.length; currentWellField++) {   // well by well
    print("well-field (" + (currentWellField + 1) + "/" + wellFieldList.length + ") ...");  //to log window
        for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel per well
            //define new filters and filter file list for currentWell and currentChannel
            filterStrings = newArray(wellFieldList[currentWellField],channelList[currentChannel] + ".tif","");      //pre-definition of strings to filter, add "_" because well strings e.g. A03, L01, C02 can be in file name at other places, e.g ..._A06_T0001F001L01A03Z01C02.tif and ".tif" to excluse well C02 instead of channel C02
            filterTerms = newArray("include", "include", "no filtering");  //pre-definition of filter types 
            wellChannelFileList = getFilteredFileList(fileList, false, false);
            if (saveStack) wellChannelFileList = correctCV7000zPlaneDigitProblem(wellChannelFileList);
            
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
                outputFileName = substring(currentImage, 0, lengthOf(currentImage) - 9 - zPlaneDigitProblem) + projectionFileTag + substring(currentImage, lengthOf(currentImage) - 7, lengthOf(currentImage));   // this should handle the 2-digit and 3-digit file names
                //outputFileName = substring(currentImage, 0, lengthOf(currentImage) - 10                    ) + projectionFileTag + substring(currentImage, lengthOf(currentImage) - 7,lengthOf(currentImage)); // here file name is 3 digit  (e.g. Z234)
                if (saveProjection) {
                    run("Z Project...", "start=" + Zstart + " stop=" + Zstop + " projection=[" + projectionType + "]");
                    saveAs("Tiff", outputPath + outputFileName);
                    print("saved projection as " + outputPath + outputFileName);  //to log window	
                    close();  //Z projection
                    }			
                if (saveStack) {
                    selectWindow("Stack"); //stack
                    saveAs("Tiff", outputPath + "stack" + File.separator + outputFileName);
                    print("saved image stack as " + outputPath + "stack" + File.separator + outputFileName);  //to log window
                    }
                }  //end if images are open
            run("Close All");	
            } //end for all channels in well
        // clear memory
        print("current memory:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");
        run("Collect Garbage");
        print("memory after clearing:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");
        saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
        }  //end for all wells
                
    //print current time to Log window and save log
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
    if (doMultipleFolders) {
        print("Macro executed successfully for this folder.\nFinished folder:", inputPaths[currentFolder],"at", year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
        } else {
        print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
        }
    selectWindow("Log");
    if(outputPath != "not available") {
        saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
        if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	
        }
	} // unitl here processing of multiple folders

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
		if (endsWith(fileListFunction[i], fileExtension)) returnedFileList = Array.concat(returnedFileList, fileListFunction[i]);
	print(returnedFileList.length + " file(s) found with extension " + fileExtension + ".");
	if (displayList) {Array.show("All files - filtered for " + fileExtension, returnedFileList);} 
	} else {
	returnedFileList = fileListFunction;	
	}
return returnedFileList;
}

//function filters all files with certain extension
//example: myFileList = getFileTypeAndCV7000metaDataFiles(myFileList, ".tif", true);
function getFileTypeAndCV7000metaDataFiles(fileListFunction, fileExtension, displayList) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
defaultCV7000metadataFileExtensionList = newArray(".icr", ".mes", ".mlf", ".mrf", ".wpi", ".wpp", ".xml");
if(lengthOf(fileExtension) > 0) {
	for (i = 0; i < fileListFunction.length; i++) {
		if (endsWith(fileListFunction[i], fileExtension)) {                    // if this is e.g. .tif
			if (indexOf(fileListFunction[i], defaultFilterStrings[0]) > 0 ||   // is "DC_sCMOS #"
				indexOf(fileListFunction[i], defaultFilterStrings[1]) > 0) {   // is "SC_BP"
				CV7000metadataFileList = Array.concat(CV7000metadataFileList, fileListFunction[i]);	
				print("Added " + fileListFunction[i] + " to CV7000 meta data file list");
				} else {
				returnedFileList = Array.concat(returnedFileList, fileListFunction[i]);
				}
			} else {                                                             // if this file has other file extension
				if (endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[0]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[1]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[2]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[3]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[4]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[5]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[6]) 
					//endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[7]) //  see definition of array defaultCV7000metadataFileExtensionList in the beginning
					) {
					CV7000metadataFileList = Array.concat(CV7000metadataFileList, fileListFunction[i]);
					print("Added " + fileListFunction[i] + " to CV7000 meta data file list");
				}
			}
		}
		print(returnedFileList.length + " file(s) found with extension " + fileExtension + ".");
		print(CV7000metadataFileList.length + " file(s) of CV7000 meta data found");
		if (displayList) {Array.show("All files - filtered for " + fileExtension, returnedFileList);Array.show("CV7000 meta data files", CV7000metadataFileList);} 
		} else {
		returnedFileList = fileListFunction;	
		}
return returnedFileList;   // note: metadataFileList is globel variable (var) and does not need to be returned
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
for (i = 0; i < CV7000metadataFileList.length; i++) { // try to find .mrf file in CV7000metadataFileList
	if (endsWith(CV7000metadataFileList[i], ".mrf")) {
		print("found .mrf file in meta data file list:", CV7000metadataFileList[i]);
		mrfFilePath = CV7000metadataFileList[i];
		}
	}
pixelSizeMrf = 0;  // by default initialize value that is given back by this function
doPixelSizeCorrection = true;  // function variable that checks it pixel sizes are unique in .mrf, otherwise funtion will return -1 
// open .mrf file and split into line array  
if (!File.exists(mrfFilePath)) {
	print("Could not find .mrf file:", mrfFilePath, "\nPixel size could not be determined and is not automatically corrected!");
    return -1;
	} else {
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

//function checks if CV7000 has 3 digits (Z01-Z99) or also 3 digits (from Z100...) in file name
//example: wellChannelFileList = correctCV7000zPlaneDigitProblem(wellChannelFileList);
function correctCV7000zPlaneDigitProblem(wellChannelFileListFunction) { 
	// Array.show("wellChannelFileList", wellChannelFileList);
	// make new array and store lenght of file names
	wellChannelFileNamelength = newArray(wellChannelFileListFunction.length);
	for (i = 0; i < wellChannelFileListFunction.length; i++) {
		wellChannelFileNamelength[i] = lengthOf(wellChannelFileListFunction[i]);
		}
	// Array.show("wellChannelFileNamelength", wellChannelFileNamelength);	
	Array.getStatistics(wellChannelFileNamelength, min, max, mean, stdDev);
	// if length min vs max differes in 1, then there are 2 and 3 digit file names. Now put 2 digit in one array and 3 digit file names in a second array
	if (max == min + 1) {
		print("found 2- and 3-digit format in CV7000 file names. File names will be sorted correctly. Length (min, max):" , min , max);
		zPlaneDigitProblem = 1;
		wellChannelFileListTwoDigits = newArray(0);
		wellChannelFileListThreeDigits = newArray(0);
		for (i = 0; i < wellChannelFileListFunction.length; i++) {
			if (wellChannelFileNamelength[i] ==  min) {
				wellChannelFileListTwoDigits[wellChannelFileListTwoDigits.length] = wellChannelFileListFunction[i];
				} else {
				wellChannelFileListThreeDigits[wellChannelFileListThreeDigits.length] = wellChannelFileListFunction[i];
				}
			}
		// finally concatenate both arrays to optain Z01-Z99, and Z100 to ... NEEDS to be extended to 4 digits at soma point...	
		wellChannelFileListFunction = Array.concat(wellChannelFileListTwoDigits, wellChannelFileListThreeDigits);
		//Array.show("wellChannelFileNamelength NEW", wellChannelFileList);			
		}
	if (max > min + 1) {
		print("found 2- and more-digit formats in CV7000 file names. File names will not be sorted correctly. Length (min, max):" , min , max);	
		waitForUser(title,"Found 2- and more-digit formats in CV7000 file names. File names will not be sorted correctly!");
		}
	return wellChannelFileListFunction;
}  // function		


//function copies files (the metadata files from CV7000) to destination folder
//example: copyFiles(metadataFileList, outputPath);
function copyFiles(listOfFilePaths, outputPath) {
// go through the list of file path, get file name and copy to destination folder 
for (i = 0; i < listOfFilePaths.length; i++) {
	currentFile = substring(listOfFilePaths[i], lastIndexOf(listOfFilePaths[i], File.separator) + 1);
	File.copy(listOfFilePaths[i], outputPath + currentFile);
	print("copied:", currentFile);	
	}  //end for
}  // function		
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////











