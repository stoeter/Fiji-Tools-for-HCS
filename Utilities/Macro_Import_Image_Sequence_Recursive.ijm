//Macro_Import_Image_Sequence_Recursive
macroName = "Macro_Import_Image_Sequence_Recursive";
macroShortDescription = "This macro opens a sequence of images defined by a regular expression as a stack.";
macroDescription = "This macro opens the images as an image sequence." +
	"<br>Works similar as File->Import-Image Sequence... command, but checks also subfolders recursively." + 
	"<br>Images are specified by a giving a regular expression." + 
	"<br>- The regex could look like this, e.g.: (?<paths>.*Olympus.*00[0-9].png$)" +
	"<br>- Select input folder" +
	"<br>- The list of paths is saved in a temp file, which will be deleted afterwards." + 
	"<br>- Optionally the list can be show and temp file can be retained." +
	"<br>- As a option the image sequence can be opened as a virtual stack (fast and memory friendly)" +
	"<br>- ATTENTION: if images have differnet sizes they will be automativally resized to fit the size of the first image in stack!";
macroRelease = "first release 28-02-2020 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools-for-HCS by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
//inputPath = getDirectory("Choose image folder... ");
inputPath = "H:\\Tumoroids\\200709_002_TumoroidsCA9_seeding\\images\\";
//outputPath = getDirectory("temp");
outputPath = inputPath;

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

timeTag = "" + year + "-" + month + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second;
logFilePath = outputPath + "Log_Import_Image_Sequence_Recursive_" + timeTag + ".txt";

//initialize => default settings
//run("Close All");
print("current memory:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//define your regex
//regexString = "(?<path>.*Olympus.*00[0-9].png$)";
regexString = "(?<path>.*C0[0-9].tif$)";
//regexString = "(?<path>.*_[JK][1-9][0-9]_.*C0[2].tif$)"; 

Dialog.create("Import Image Sequence Recursive");
Dialog.addString("Regular expresion", regexString, 35);
Dialog.addCheckbox("Open as virtual stack?", true);
Dialog.addCheckbox("Display file list?", false);
Dialog.addCheckbox("Retain file with path list?", true);
Dialog.show(); 
regexString = Dialog.getString();
useVirtualStack = Dialog.getCheckbox();
displayFileList = Dialog.getCheckbox();
retainFile = Dialog.getCheckbox();
print("\nRegular expresion", regexString, "; open as virtual stack", useVirtualStack, "; display file list", displayFileList, "; retain file with path list", retainFile, "\n");

run("Fiji-Tools-for-HCS-plugin");  //run("Fiji-Tools-ForHCS");

//define your path and pass it onto the result variable (if result variable is an existing path, then all file names will be read and the regular expression is applied on them...)
//optionalPath = getDirectory("plugins");
//print(optionalPath);
//regexResults = optionalPath;
regexResults = inputPath;

//define you regex query => here empty because the regex will be applied on the files found in given path
stringArrayForQuery = newArray(0);

//launch the regex query
Ext.getRegexMatchesFromArray(stringArrayForQuery, regexString, regexResults);

//since result is passed back as single string, regex groups can be split into an array using the (||) ...");
regexGroupArray = split(regexResults, "||");
Array.print(regexGroupArray);

//save the list of paths in a FIJI temp folder (tab separated elements needt to be seprated by line breaks)
if(regexGroupArray.length < 2) {
	print("no images found");
	waitForUser("No images found!");
	} else {
	tempFile = outputPath + "listOfPaths_" + timeTag + ".txt";
	print("saving list of paths here:", tempFile);	
	File.saveString(replace(regexGroupArray[1], "\t", "\n"), tempFile);
	if (File.exists(tempFile) == 0) print("could not save file (access rights?):", tempFile);
	//first group is regex query names (here just "paths"), second group (=[1]) is array of paths)
	pathArray = split(regexGroupArray[1], "\t");
	if (displayFileList) Array.show(pathArray);
	if (useVirtualStack) {
		useVirtualStack = " use";
		} else {
		useVirtualStack = "";	
		}

	//print(tempFile);
	//print("open=" + tempFile + useVirtualStack);
	run("Stack From List...", "open=" + tempFile + useVirtualStack);
	rename("Image Sequence - " + regexString);
	print("opened", nSlices , "images in a stack");
	if (!retainFile && File.exists(tempFile)) File.delete(tempFile);  //delete temp file 
	}

//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", logFilePath);
//if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 