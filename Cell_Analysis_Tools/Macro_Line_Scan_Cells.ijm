//Line_Scan_Cells
macroName = "Line_Scan_Cells";
macroShortDescription = "With this Macro you can speed up your line scans.";
macroDescription = "This macro writes links (URLs) to the log window." +
	"<br>- Select input folder" +
	"<br>- Select ouput folder for saving files (plot profile, cytoplasmic background and analyzed cells)" + 
	"<br>- Follow the instructions";
macroRelease = "first release 19-07-2016 by Sriyash Mangal (mangal(at)biologie.uni-muenchen.de) & Martin Stöter (stoeter(at)mpi-cbg.de)";
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
//inputPath = "N:\\cv7000images\\015ZA160620B-Pilot_20160711_104414\\ZmaxTestSet\\";
//outputPath = "N:\\cv7000images\\015ZA160620B-Pilot_20160711_104414\\TestOutput\\";

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=90 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("ZallC02","_D04_","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("include", "include", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();
print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

lineScanWindow = "Line Scan Data";
lineWidth = 4;

//get file list ALL
//fileList = getFileList(inputPath);
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings

//setBatchMode(true);
for (currentFile = 0; currentFile < fileList.length; currentFile++) {
	// open files one after the other...
	IJ.redirectErrorMessages();
	open(fileList[currentFile]);
	currentImage = getTitle();
	currentImageNoExt = substring(currentImage, 0, lengthOf(currentImage) - 4);
	showProgress(currentFile / fileList.length);
	run("Enhance Contrast", "saturated=0.35");
	run("Select None");
	numberOfProfile = 0;
	doLineScan = true;

	while (doLineScan) {
		Dialog.create("Analyse this image?");
		Dialog.addCheckbox("Check to perform a line scan?", true);
		Dialog.addNumber("Line width?", lineWidth);
		Dialog.show(); 
		doLineScan = Dialog.getCheckbox();
		lineWidth = Dialog.getNumber();
		run("Line Width...", "line=" + lineWidth); 
	
		if (doLineScan) {
			// user interactivity to draw profile line
			numberOfProfile++;
			setTool("polyline");
			//print(selectionType());
			while (selectionType()!= 6) {
				waitForUser("Line Scan", "Please draw a line along the cell cortex, starting from left pole of the cell");
				if (selectionType()!= 6) {  //Return error if line is not drawn. Ask user to exit or draw line.
					showMessageWithCancel("Error","Invalid selection. \nPress OK to continue and use segmented line tool to draw line around cortex. \nPress Cancel to exit");
					setTool("polyline");
					}
				}
			getSelectionBounds(coodinateX, coodinateY, width, height); //will be used to draw bounding box around cell later for duplicating region
			//print(x, y, width, height);	
				
			run("Plot Profile");
			Plot.getValues(x, y);
			//Overlay the line scan with the image
			selectWindow(currentImage);
			getLocationAndSize(imageLocationX, imageLocationY, imageWidth, imageHeight);
			run("Add Selection...");	
			selectWindow("Plot of " + currentImageNoExt);
			setLocation(imageLocationX + imageWidth, imageLocationY + imageHeight / 2);
				
			/* plotting result to text windwo is very slow...
			if (isOpen(lineScanWindow)) {
   		 	print("[" + lineScanWindow + "]", "\\Update:"); // clears the Line scan window
				} else {
				run("Text Window...", "name=[" + lineScanWindow + "] width=30 height=50 menu");	
				}
			print("[" + lineScanWindow + "]", "Fiji distance"+ "\t"+ "Pixel Intensity\n");
			for (i = 0; i < x.length; i++) print("[" + lineScanWindow + "]", x[i]+ "\t"+ y[i] + "\n");*/
		
			// plot line scan data to result window 
			run("Clear Results");
			for (i = 0; i < x.length; i++) {
		    	setResult("Fiji distance", i, x[i]);
	   			setResult("Pixel Intensity", i, y[i]);
   		 		}
			updateResults();
			// Save as spreadsheet compatible text file
			print(outputPath + currentImageNoExt + "_lineScan_" + getNumberToString(numberOfProfile, 0, 2) + ".txt");
			saveAs("Results", outputPath + currentImageNoExt + "_lineScan_" + getNumberToString(numberOfProfile, 0, 2) + ".txt");
	
			//select cytoplasmic background
			selectWindow(currentImage);
			run("Select None");
			setTool("rectangle");
			while (selectionType() == -1 || selectionType() > 3) {  // allow  areas 0=rectangle, 1=oval, 2=polygon, 3=freehand, but not -1 if there is no selection. 
				waitForUser("Define Background", "Please draw a box in cytoplasm to measure mean cytoplasmic background");
				if (selectionType() == -1 || selectionType() > 3) {  //Return error if area is not drawn. Ask user to exit or draw area.
					showMessageWithCancel("Error","Invalid selection. \nNo area selection found. \nPress OK to continue and draw the box. \nPress Cancel to exit");
					setTool("rectangle");
					}
				}
			// measure background to result window 
			run("Clear Results");
			run("Measure");
			//Save background to text file
			print(outputPath + currentImageNoExt + "_background_" + getNumberToString(numberOfProfile, 0, 2) + ".txt");
			saveAs("Results", outputPath + currentImageNoExt + "_background_" + getNumberToString(numberOfProfile, 0, 2) + ".txt");		

			//Overlay the background box
			selectWindow(currentImage);
			Stack.getPosition(channel, slice, frame); //to print slice position later
			run("Add Selection...");
			//Crop the image
			makeRectangle(coodinateX - 20, coodinateY - 20 , width + 40, height + 40);
			run("Duplicate...", "Analysed Cell");
			run("Grays");
			//Print slice position on duplicated image
			setFont("SanSerif", 10, "antialiased");
 			setColor("white");
			Overlay.drawString("c:" + channel + "/ z:" + slice + "/ t:" + frame,  5,15);
  			Overlay.show();
			run("Enhance Contrast", "saturated=0.35");
	
			//Save the image file
			print(outputPath + currentImageNoExt + "_analysedCell_" + getNumberToString(numberOfProfile, 0, 2) + ".txt");	
			saveAs("png", outputPath + currentImageNoExt + "_analysedCell_" + getNumberToString(numberOfProfile, 0, 2) + ".txt");
			close();
			}  //if 
		if (isOpen("Plot of " + currentImageNoExt)) close("Plot of " + currentImageNoExt);	
		saveLog(outputPath + "Log_temp_" + tempLogFileNumber +".txt");
		}	// while
		close(currentImage);
	}  // for 

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

