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
macroRelease = "first release 11-02-2020 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
//outputPath = getDirectory("Choose result image folder... or create a folder");
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
regexString = "(C0[4].tif)";
rollingBallRadius = 5;
gaussianBlurRadius = 1;
prominence = 100;
fileTag = "_IJ-maxSeed";
renameFiles = true;
availableOutputTypes = newArray("PNG", "Tiff");

Dialog.create("Settings for movie generation");
Dialog.addString("Regular expresion", regexString);
Dialog.addNumber("Size of rolling ball radius (0 for not background correction)", rollingBallRadius);
Dialog.addNumber("Size of Gaussian blur radius (0 for not Gaussian blur)", gaussianBlurRadius);
Dialog.addNumber("Background threshold (Prominence)", prominence);
Dialog.addString("File tag for result images", fileTag);
Dialog.addChoice("Output image type", availableOutputTypes);
Dialog.addCheckbox("Rename files?", renameFiles);
Dialog.addCheckbox("Hide image display?", true);
Dialog.show(); 
regexString = Dialog.getString();
rollingBallRadius = Dialog.getNumber();
gaussianBlurRadius = Dialog.getNumber();
prominence = Dialog.getNumber();
fileTag = Dialog.getString();
outputType = Dialog.getChoice();
renameFiles = Dialog.getCheckbox();
hideImages = Dialog.getCheckbox();
print("Regular expresion", regexString, "; size of rolling ball radius", rollingBallRadius, "; size of Gaussian blur radius", gaussianBlurRadius, "; background threshold (Prominence)", prominence, "; file tag for result images", fileTag, "; Output image type", outputType, "; rename files?", renameFiles);

if(!File.isDirectory(outputPath)) {
	File.makeDirectory(outputPath)
	print("created directory", outputPath);
	}

setBatchMode(hideImages);
// process the images
print("opening images...");
run("Image Sequence...", "open=" + inputPath + " file=" + regexString + " sort");
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
print("finding maximum and saving images...");
//run("Image Sequence... ", "format=TIFF use save=" + outputPath);
//outputPath = "Z:\\cv7000images\\tempCP5\\828AZ190826A-HeLa-6LNPs_20190829_154804\\828AZ190826A-HeLa-6LNPs\\Fiji-BkgSub\\";
//prominence = 100;
//fileTag = "_IJ-maxSeed";
//renameFiles = true;
//numberOfImages = nSlices;
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
