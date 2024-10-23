//StarDist_with_preproseccing
macroName = "Macro_StarDist_with_preproseccing";
macroShortDescription = "This macro runs StarDist, but allows several pre-processing steps before-hand.";
macroDescription = "This macro reads single .tif images from the chosen folder (including subfolders)" +
	"<br>Pre-processing like log transformation, dimension scaling, and background subtraction are applicable." +
	"<br>StarDist will run on filteed images with adjustable parameters and saves them in StarDist folder of input folder."
	"<br>Label images or overlays can be exported.";
macroRelease = "first release 23-10-2024 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
var inputPath = "";
var outputPath = "not available"; 

doLogTransformation = false;
xyScale = 0.5;
rollingBallRadius = 0;
outputFileTag = "_label";
outputFileOverlayTag = "_overlay";
defaultOutputfolderName = "StarDist";

//	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + imageNameToSD + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'98.8', 'probThresh':'0.75', 'nmsThresh':'0.02', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
modelSD = "Versatile (fluorescent nuclei)";
normalizationSD = "true";
percentileBottomSD = 1.00;
percentileTopSD = 98.80;
probThreshSD = 0.40;
nmsThreshSD = 0.15;
outputTypeSD = "Both";
nTilesSD = 1;
excludeBoundarySD = 2;
    
inputPath = getDirectory("Choose image folder... ");

Dialog.create("Set StarDist options");
Dialog.addMessage("====== Input image pre-processing ======");
Dialog.addCheckbox("Do intensity log transformation?", doLogTransformation);
Dialog.addNumber("Pre-scaling factor of image", xyScale);
Dialog.addNumber("Subtract Background? (0 = no bkg. subtraction)", rollingBallRadius);
Dialog.addMessage("====== StarDist model ======");
Dialog.addChoice("Choose StarDist model:", newArray("Versatile (fluorescent nuclei)"));
Dialog.addMessage("====== Normalization ======");
Dialog.addChoice("Do normalization?", newArray("true", "false"));
Dialog.addSlider("Percentile low:", 0.0, 100.0, percentileBottomSD);
Dialog.addSlider("Percentile high:", 0.0, 100.0, percentileTopSD);
Dialog.addMessage("====== NMS Post-processing ======");
Dialog.addSlider("Probability/Score threshold:", 0.0, 1.0, probThreshSD);
Dialog.addSlider("Overlap threshold:", 0.0, 1.0, nmsThreshSD);
Dialog.addMessage("====== Output settings ======");
Dialog.addString("StarDist output file tag:", outputFileTag);
Dialog.addString("Change default output folder name?", defaultOutputfolderName);
Dialog.addChoice("Output type of SD (Both=overlays, Label=label)?", newArray("Label Image", "Both"), outputTypeSD);
Dialog.show();
doLogTransformation = Dialog.getCheckbox();
xyScale = Dialog.getNumber();
rollingBallRadius = Dialog.getNumber();
modelSD = Dialog.getChoice();
normalizationSD = Dialog.getChoice();
percentileBottomSD = Dialog.getNumber();
percentileTopSD = Dialog.getNumber();
probThreshSD = Dialog.getNumber();
nmsThreshSD = Dialog.getNumber();
outputFileTag = Dialog.getString();
defaultOutputfolderName = Dialog.getString();
outputTypeSD = Dialog.getChoice();
print("log transformation:", doLogTransformation, "; scaling factor:", xyScale, "; subtract Background:", rollingBallRadius, "; StarDist model:", modelSD, "normalization:", normalizationSD, "percentile low:", percentileBottomSD, "percentile high:", percentileTopSD, "probability threshold:", probThreshSD, "overlap threshold:", nmsThreshSD, "output file tag:", outputFileTag, "output folder name", defaultOutputfolderName, "output type", outputTypeSD);
//print("Default output folder was set to:", defaultOutputfolderName);

// ===== organize output (folder) settings  =====
//outputPath = substring(inputPaths[currentFolder], 0, lastIndexOf(inputPaths[currentFolder], File.separator)) + File.separator + "Zprojection" + File.separator;
outputPath = inputPath + File.separator + defaultOutputfolderName + File.separator;
//outputPath = getDirectory("Choose result image folder... or create a folder");
if (!File.exists(outputPath)) {
	File.makeDirectory(outputPath);
    print("New output folder -> made folder for StarDist files: " + outputPath);  //to log window
    }
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
//run("Close All");
run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set array variables
batchMode = true;
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("C01.tif","","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("include", "no filtering", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
    
setDialogImageFileFilter();
//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);			 //filter for extension
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings

waitForUser("Do you really want to open " + fileList.length + " files?" + "\n\n" + "Otherwise press 'ESC' and check image list and filter text!");

//setBatchMode(batchMode);
//go through all file
for (currentFile = 0; currentFile < fileList.length; currentFile++) {
	showProgress(currentFile / fileList.length);
	showStatus("processing" + fileList[currentFile]);
	if (endsWith(fileList[currentFile], ".tif")) {   //check if it is right file and handle error on open()
		IJ.redirectErrorMessages();
		run("TIFF Virtual Stack...", "open=[" + fileList[currentFile] + "]");
		} else {
		IJ.redirectErrorMessages();
		open(fileList[currentFile]);
		}	
    if (nImages > 0) {			//if image is open  
   		fileName = getTitle();
		print("opened (" + (currentFile + 1) + "/" + fileList.length + "):", fileList[currentFile]);  //to log window

		imageName = getTitle();
		getDimensions(width, height, channels, slices, frames);
		if (doLogTransformation) run("Log");
		run("Scale...", "x=" + xyScale + " y=" + xyScale + " interpolation=Bilinear average create");
		if (rollingBallRadius > 0) run("Subtract Background...", "rolling=" + rollingBallRadius);
		imageNameToSD = getTitle();
		//run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + imageNameToSD + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'98.8', 'probThresh':'0.05', 'nmsThresh':'0.15', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		//run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + imageNameToSD + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'98.8', 'probThresh':'0.75', 'nmsThresh':'0.02', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + imageNameToSD + "', 'modelChoice':'" + modelSD + "', 'normalizeInput':'" + normalizationSD + "', 'percentileBottom':'" + percentileBottomSD + "', 'percentileTop':'" + percentileTopSD + "', 'probThresh':'" + probThreshSD + "', 'nmsThresh':'" + nmsThreshSD + "', 'outputType':'" + outputTypeSD + "', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		if (outputTypeSD == "Both" || outputTypeSD == "Label Image") {
			selectImage("Label Image");
			run("Scale...", "width=" + width + " height=" + height  + " interpolation=None average create");
			print("save:", outputPath + substring(imageName, 0, lengthOf(imageName) - 4) + outputFileTag + ".tif");
			saveAs("Tiff", outputPath + substring(imageName, 0, lengthOf(imageName) - 4) + outputFileTag + ".tif");	
			}
		if (outputTypeSD == "Both") {
			selectWindow(imageNameToSD);
			setMinAndMax(0, 300);
			roiManager("Show All");
			print("save:", outputPath + substring(imageName, 0, lengthOf(imageName) - 4) + outputFileOverlayTag + ".tif");
			saveAs("Tiff", outputPath + substring(imageName, 0, lengthOf(imageName) - 4) + outputFileOverlayTag + ".tif");	
			roiManager("reset");
			}
		close("*");
		//waitForUser("check");     	
   		} else { //if no images open
		print("file (" + (currentFile + 1) + "/" + fileList.length + "): ", fileList[currentFile], " could not be opened."); 	//if open() error
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
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//function opens a dialog to set text list for filtering a list
//example: setDialogImageFileFilter();
//this function set interactively the global variables used by the function getFilteredFileList
//this function needs global variables! (see below)
/*
//var fileExtension = ".tif";                                                  //default definition of extension
//var filterStrings = newArray("","","");                                      //default definition of strings to filter
//var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
//var filterTerms = newArray(filterStrings.length); for  (i = 0; i < filterStrings.length; i++) {filterTerms[i] = "no filtering";} //default definition of filter types (automatic)
//var filterTerms = newArray("no filtering", "no filtering", "no filtering");  //default definition of filter types (manual)
//var displayFileList = false;                                                 //shall array window be shown? 
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


////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////