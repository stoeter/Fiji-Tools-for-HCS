//Macro_Fiji_Find_Maxima
macroName = "Macro_Fiji_Find_Maxima";
macroShortDescription = "This macro saves images with identified maxima as binary image into a new folder.";
macroDescription = "This macro opens the images as an image sequence." +
	"<br>Images are specified by a giving a regular expression." + 
	"<br>- Select input folder" +
	"<br>- Specify ouput folder name for corrected images." + 
	"<br>- Rolling ball radius for background subtraction can be set. (enter 0 for no background correction)" +
	"<br>- Enter background value. (Prominence, default = 100)" +
	"<br>- more help: https://imagej.nih.gov/ij/docs/menus/process.html#find-maxima";
macroRelease = "second release 18-11-2024 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
print(macroName, "(" + macroRelease + "),", "ImageJ version:", IJ.getFullVersion, "\nStart:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
print(macroHelpURL);
print(generalHelpURL);
print("https://imagej.nih.gov/ij/docs/menus/process.html#find-maxima");

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools-for-HCS by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
//inputPath = "Z:/cv7000images/tempCP2/015AZ180625A-9doseRes-stained_20180720_152958/015AZ180625A-9doseRes-stained/";
//outputPath = getDirectory("Choose result image folder... or create a folder");inputPath = "E:\\BTSData\\CorrectedMeasurementData\\Martin\\003ih241111A-HelaEEA1KO-smA_20241116_091213\\Zprojection\\";
newFolderName = "Fiji-MaxSeed";
outputPath = inputPath + newFolderName + File.separator;

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min integrated median stack display redirect=None decimal=3");
run("Input/Output...", "jpeg=90 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
print("current memory:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
regexString = "C0[4].tif";
processWellByWell = false;
rollingBallRadius = 5;
gaussianBlurRadius = 1;
prominence = 100;
fileTag = "_IJ-maxSeed";
renameFiles = true;
availableOutputTypes = newArray("PNG", "Tiff");

Dialog.create("Settings for movie generation");
Dialog.addString("Regular expresion", regexString);
Dialog.addCheckbox("Process images well-by-well?", processWellByWell);
Dialog.addNumber("Size of rolling ball radius (0 for not background correction)", rollingBallRadius);
Dialog.addNumber("Size of Gaussian blur radius (0 for not Gaussian blur)", gaussianBlurRadius);
Dialog.addNumber("Background threshold (Prominence)", prominence);
Dialog.addString("File tag for result images", fileTag);
Dialog.addChoice("Output image type", availableOutputTypes);
Dialog.addCheckbox("Rename files?", renameFiles);
Dialog.addCheckbox("Hide image display?", true);
Dialog.show(); 
regexString = Dialog.getString();
processWellByWell = Dialog.getCheckbox();
rollingBallRadius = Dialog.getNumber();
gaussianBlurRadius = Dialog.getNumber();
prominence = Dialog.getNumber();
fileTag = Dialog.getString();
outputType = Dialog.getChoice();
renameFiles = Dialog.getCheckbox();
hideImages = Dialog.getCheckbox();
print("Regular expresion", regexString, "; process well-by-well", processWellByWell, "; size of rolling ball radius", rollingBallRadius, "; size of Gaussian blur radius", gaussianBlurRadius, "; background threshold (Prominence)", prominence, "; file tag for result images", fileTag, "; Output image type", outputType, "; rename files?", renameFiles);

if(!File.isDirectory(outputPath)) {
	File.makeDirectory(outputPath)
	print("created directory", outputPath);
	}

//set (array) variables
var defaultFilterStrings = newArray("DC_sCMOS #","SC_BP","");
var CV7000metadataFileList = newArray(0);
var fileExtension = ".tif";
displayFileList = false;   
displayMetaData = false; 

setBatchMode(hideImages);
if (processWellByWell) {
	fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders                          
	if (fileList.length == 0) exit("No files to process"); 
	fileList = getFileTypeAndCV7000metaDataFiles(fileList, fileExtension, displayFileList);   // new funtion to store the CV7000 meta data files in separate list (CV7000metadataFileList)
	wellList = getUniqueWellListCV7000(fileList, displayMetaData);
	} else {
	wellList = newArray("");	
	}

//go through all wells
for (currentWell = 0; currentWell < wellList.length; currentWell++) {   // well by well
	print("well (" + (currentWell + 1) + "/" + wellList.length + ") ...");  //to log window
	currentRegexString = wellList[currentWell] + ".*" + regexString;

	// process the images
	print("opening images...");
	run("Image Sequence...", "open=" + inputPath + " file=(" + currentRegexString + ") sort");
	run("Enhance Contrast", "saturated=0.35");
	numberOfImages = nSlices;
	// check if file names are too long for subtite in stack
	fileNameSubTitle = getInfo("slice.label");
	if(lengthOf(fileNameSubTitle) >= 60) {
		print("File name that will be used for saving:", fileNameSubTitle);
		print("Subtitle of stack cannot handle full file names! \nDue to limit of 60 characters in subtitle of Fiji stacks the file name might be chopped off at the end,\nand files could be wrong or overwritten! \nPlease press <ESC> to cancel or <OK> to go on.");
		waitForUser("File name that will be used for saving:\n\n" + fileNameSubTitle + "\n\nSubtitle of of stack cannot handle full file names! \nDue to limit of 60 characters in subtitle of Fiji stacks the file name might be chopped off at the end,\nand files could be wrong or overwritten! \n\nPlease press <ESC> to cancel or <OK> to go on."); 
	}
	if(rollingBallRadius > 0) {
		print("subtracting background from", nSlices, "images...");
		run("Subtract Background...", "rolling=" + rollingBallRadius + " stack");
		}
	if(gaussianBlurRadius > 0) {
		print("applying Gaussina blur on", nSlices, "images...");
		run("Gaussian Blur...", "sigma=" + gaussianBlurRadius + " stack");
		}	
	print("finding maximum, renaming files for regex:" + currentRegexString + " and saving images...");
	for(currentSlice = 1; currentSlice <= numberOfImages; ++currentSlice) {
		showProgress(currentSlice, numberOfImages);
		setSlice(currentSlice);
		imageName = getMetadata("Label");
		//imageName = substring(imageName, 0, indexOf(imageName, ":"));
		//print(imageName);
		run("Find Maxima...", "prominence=" + prominence + " output=[Single Points]");
		if(renameFiles) {
			if(outputType == "Tiff") {
				newFileName = substring(imageName, 0, lengthOf(imageName) - 4) + fileTag + ".tif";
				} else {
				newFileName = substring(imageName, 0, lengthOf(imageName) - 4) + fileTag + ".png";	
				}
			} else {
			newFileName = imageName;
			}
		print("Saving:" + currentSlice, "/", numberOfImages, "saving:", newFileName); 	
		saveAs(outputType, outputPath + newFileName);
		close();
		}
	}
close();

// debugging or renaming ...
//outputPath = "Z:\\cv7000images\\021AZ180625A-3tcFISH_20180713_193421\\Zmax\\Fiji-BkgSub\\";
//outputPath = "Z:\\cv7000images\\015AZ180625\\015AZ180625A-9doseRes-stained2_20180801_125306\\015AZ180625A-9doseRes-stained2\\Fiji-BkgSub\\";
//renameFiles = true;
//fileTag = "_IJ-bkgSub";
/*if(renameFiles) {
	print("renaming files...");
	fileList = getFileList(outputPath);
	for(currentFile = 0; currentFile < fileList.length; ++currentFile) 	{
		showProgress(currentFile, fileList.length);
		if(endsWith(fileList[currentFile], fileTag + substring(fileList[currentFile], lengthOf(fileList[currentFile]) - 4))) {
			print(currentFile, "/", fileList.length, "ignoring:", fileList[currentFile]);
			} else {
			newFileName = substring(fileList[currentFile], 0, lengthOf(fileList[currentFile]) - 4) + fileTag + substring(fileList[currentFile], lengthOf(fileList[currentFile]) - 4); 
			//print(currentFile, "/", fileList.length, "renaming to:", newFileName);
			File.rename(outputPath + fileList[currentFile], outputPath + newFileName);
			print("\\Update:" + currentFile, "/", fileList.length, "renaming to:", newFileName); 
			}
		}	
	}*/

//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 

print("current memory:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");
run("Collect Garbage");
print("memory after clearing:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");

/////////////////////////////////////////////////////////////////////////////////////////////
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////

//function gets all files from folders and subfolders
//example: myFileList = getFileListSubfolder("/home/myFolder/", true);
function getFileListSubfolder(inputPathFunction, displayList) {
fileListFunction = getFileList(inputPathFunction);  //read file list
Array.sort(fileListFunction);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileListFunction.length; i++) {
	//print(i, inputPathFunction + fileListFunction[i]);
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	//print("fixed", i, inputPathFunction + fileListFunction[i]);
	if (endsWith(fileListFunction[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPathFunction + fileListFunction[i], displayList);
		returnedFileList = Array.concat(returnedFileList, returnedFileListTemp);
		} else {  									//if it is a file
		returnedFileList = Array.concat(returnedFileList, inputPathFunction + fileListFunction[i]);
		//print(i, inputPathFunction + fileListFunction[i]); //to log window
		}
	}
if(inputPathFunction == inputPath) { //if local variable is equal to global path variable = if path is folder and NOT subfolder
	print(returnedFileList.length + " file(s) found in selected folder and subfolders."); 	
	if (displayList) {Array.show("All files - all",returnedFileList);} 	
	}
return returnedFileList;
}

//function filters all files with certain extension
//example: myFileList = getFileTypeAndCV7000metaDataFiles(myFileList, ".tif", true);
function getFileTypeAndCV7000metaDataFiles(fileListFunction, fileExtension, displayList) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
defaultCV7000metadataFileExtensionList = newArray(".icr", ".mes", ".mlf", ".mrf", ".wpi", ".wpp", ".xml");
if (lengthOf(fileExtension) > 0) {
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
Array.print(returnedWellList);
if (displayList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}
