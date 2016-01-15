//Macro_BDpathway_Montage_Splitter
macroName = "BDpathway_Montage_Splitter";
macroShortDescription = "This macro splits montages from BD Pathway 855 microscope .tif images into individual images.";
macroDescription = "This macro splits montages with multile fields acquired with BD Pathway 855 automated microscope" +
	"\nand saves images as stack or as single individual images (.tif). The chosen folder will be searched for images including subfolders" +
	"\nand the list of files to be processed can be filters for text or tags in the file path.";
macroRelease = "first second 05-02-2015 by Martin Stöter (stoeter(at)mpi-cbg.de)";
macroHelpURL = "http://idisk-srv1.mpi-cbg.de/knime/FijiUpdate/TDS%20macros/" + macroName + ".htm";
macroHtml = "<html>" 
	+"<font color=red>" + macroName + "/n" + macroRelease + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>" + macroHelpURL + "</font> <br>"
	+"<font color=black>...get this URL from Log window!</font> <br>"
    	+"</font>";
    	
//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName,"\nStart:",year+"-"+month+"	-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
print(macroHelpURL);

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools-for-HCS by TDS@MPI-CBG)\n \n" + macroShortDescription + "\nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set array variables
batchMode = true;
displayFileList = false;
availableFilterTerms = newArray("no filtering", "include", "exclude");
filterStrings = newArray(3);
filterTerms = newArray(3);

Dialog.create("Define files to process!");  //enable use inveractivity
Dialog.addNumber("Number of images in montage per row (=x)?", 4);
Dialog.addNumber("Number of images in montage per columnrow (=y)?", 2);
Dialog.addChoice("Save stack or single images?", newArray("save single images", "save stack"));	//add extension
Dialog.addMessage("Define the files to be processed:");
Dialog.addString("File type (extension)?", ".tif");	//add extension
for (i = 0; i < 3; i++) {
	Dialog.addString((i + 1) + ") Filter this text from file list: ", "");	
	Dialog.addChoice((i + 1) + ") Files with text are included/excluded?", availableFilterTerms);	
	}
Dialog.addCheckbox("Check file lists?", displayFileList);	//if checke file lists will be displayed
Dialog.show();
montageImagesPerRow  = Dialog.getNumber();
montageImagesPerColumn = Dialog.getNumber();
saveMode = Dialog.getChoice();
fileExtension = Dialog.getString();
for (i = 0; i < 3; i++) {
	filterStrings[i] = Dialog.getString();	
	filterTerms[i] = Dialog.getChoice();	
	}
displayFileList = Dialog.getCheckbox();

//get file list ALL
fileList = getFileListSubfolder(inputPath); 
if (displayFileList) {Array.show("All files - all",fileList);}
print(fileList.length + " files found in selected folder and subfolders."); 
//get file list extension filtered
fileList = getFileType(fileList,fileExtension);
if (displayFileList) {Array.show("All files - filtered for " + fileExtension,fileList);}
print(fileList.length + " files found with extension " + fileExtension + "."); 
//get file list filtered for text
for (i = 0; i < 3; i++) {
	if (filterTerms[i] != availableFilterTerms[0]) {
		fileList = filterFileList(fileList, filterStrings[i], filterTerms[i]);
		if (displayFileList) {Array.show(fileExtension + " files - after filter for " + filterStrings[i],fileList);}
		print(fileList.length + " files found after filter: " + filterTerms[i] + " text " + filterStrings[i] + "."); 
		}
	}
//for (j=0; j < fileList.length; j++) print(j,fileList[j]);

//tidy up and close windows
if (displayFileList) {
	waitForUser("Check if the list of files found/filtered is correct!" + "\n" + "Otherwise press 'ESC' and check image list!");
	windowList = getList("window.titles");
	for (i = 0; i < windowList.length; i++) {
		if (indexOf(windowList[i]," files - ") > 0) {
			selectWindow(windowList[i]);
			run("Close");
			}
		}
	}
Array.sort(fileList);

setBatchMode(batchMode);
//go through all file
for (currentFile = 0; currentFile < fileList.length; currentFile++) {
	if (endsWith(fileList[currentFile],fileExtension)) {   //check if it is right file and handle error on open()
		showProgress(currentFile/fileList.length);
		showStatus("processing " + fileList[currentFile]);
		IJ.redirectErrorMessages();
		run("TIFF Virtual Stack...", "open=[" + fileList[currentFile] + "]");
		montageImage = getTitle();
		showProgress(currentFile / fileList.length);
        showStatus("processing" + fileList[currentFile]);
        if (nImages > 0) {			//if image is open    	
			run("Montage to Stack...", "images_per_row=" + montageImagesPerRow + " images_per_column=" + montageImagesPerColumn + " border=0");
			stackImage = getTitle();
			getDimensions(width, height, channels, slices, frames);
			//print(width, height, channels, slices, frames);
			print("opened (" + (currentFile + 1) + "/" + fileList.length + "):", fileList[currentFile]);  //to log window
			selectWindow(montageImage);
			close();
			selectWindow(stackImage);
			newFileName = substring(fileList[currentFile],lengthOf(inputPath),lengthOf(fileList[currentFile]));
			newFileName = replace(newFileName,File.separator,"_");
			if (saveMode == "save stack") {   //save stack
				saveAs("Tiff", outputPath + newFileName);	
				print("saved montage as stack: " + newFileName);
				close();			
				} else {						//save single images
				for (currentField = 1; currentField <= slices; currentField++) { //now iterate through all fields and save as .tif with new fiel number	
					selectWindow(stackImage);
					setSlice(currentField);
					run("Duplicate...", "tempImage");
					newFileNameField = substring(newFileName,0,indexOf(newFileName,fileExtension)) + "_f" + d2s(currentField,0) + fileExtension;
					saveAs("Tiff", outputPath + newFileNameField);
					close();
					print("saved image of montage (" + currentField + "/" + slices + "): " + outputPath + newFileNameField);
					}
				selectWindow(stackImage);
				close();
				}
        	} else { //if no images open
			print("file (" + (currentFile + 1) + "/" + fileList.length + "): ", fileList[currentFile], " could not be opened."); 	//if open() error
			}	
		} else { //if file has different extensionn
		print("file (" + (currentFile + 1) + "/" + fileList.length + "): ", fileList[currentFile], " was skipped."); 	//if not .tif
		}
	}
		
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	

/////////////////////////////////////////////////////////////////////////////////////////////
////////			F U N C T I O N S				/////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//function get all files from foldern and all subfolders
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

//function finds all files with certain extension
function getFileType(fileList,extension) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
for (i = 0; i < lengthOf(fileList); i++) {
	if (endsWith(fileList[i],extension)) returnedFileList = Array.concat(returnedFileList,fileList[i]);
	}
return returnedFileList;
}

//function filter a file list for a certain string
function filterFileList(fileList,fileTag,filter) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
for (i = 0; i < lengthOf(fileList); i++) {
	if (filter == "include" && indexOf(fileList[i],fileTag) != -1) returnedFileList = Array.concat(returnedFileList,fileList[i]);
	if (filter == "exclude" && indexOf(fileList[i],fileTag) <= 0) returnedFileList = Array.concat(returnedFileList,fileList[i]);
	}
return returnedFileList;
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////