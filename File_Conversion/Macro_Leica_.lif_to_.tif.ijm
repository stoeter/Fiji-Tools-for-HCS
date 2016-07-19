//Leica_.lif_to_.tif
macroName = "Leica_.lif_to_.tif";
macroShortDescription = "This macro imports .lif image files from Leica microscope, splits channels and saves each channel.";
macroDescription = "This macro imports .lif image files from Leica microscope, splits channels and fields and saves images as .tif" +
	"\nChannels can be saved as stacks or as image sequence." +
	"\nTags can be given to each channel.";
macroRelease = "first release 13-05-2016 by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;
macroHtml = "<html>"
	+"<font color=red>" + macroName + "\n" + macroRelease + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
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
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 

//configure
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Options...", "iterations=1 count=1 black edm=Overwrite");
run("Close All");

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//set variables
imageSuffix = newArray("_Ch1", "_Ch2", "_Ch3", "_Ch4", "_Ch5");  //reset array of default channel names
manualMode = true;
useTags = false;   // be careful with image tag it might contain characters that cannot be used as filenames, e.g. (c:1/3; z:1/12 - 15_1_2)...
saveImageSequence = false;  //for saving individual images of stack
	
	
//get file list and well list
fileList = getFileList(inputPath);
Array.sort(fileList);

//go through all file
for (currentFile = 0; currentFile < fileList.length; currentFile++) {
	if (endsWith(fileList[currentFile],".lif")) {   //check if it is right file and handle error on open()
		IJ.redirectErrorMessages();
		run("Bio-Formats", "open=[" + inputPath + fileList[currentFile] + "] autoscale color_mode=Composite open_files open_all_series view=Hyperstack stack_order=XYCZT");
		//run("Bio-Formats (Windowless)", "open=[" + inputPath + fileList[currentFile] + "] autoscale color_mode=Composite concatenate_series open_files open_all_series view=Hyperstack stack_order=XYCZT");  //open(inputPath + fileList[currentFile]);
		//run("Bio-Formats", "open=C:\\Users\\stoeter\\Desktop\\testImage_lif\\160425_IC50_PZ_15_20.l color_mode=Default open_all_series view=Hyperstack stack_order=XYCZT use_virtual_stack");
		numberOfFields = nImages;
		print(numberOfFields, "images opened...");
        for (currentImageField = 1; currentImageField <= numberOfFields; currentImageField++) {
			print(currentImageField,"/",numberOfFields);
	        if (nImages > 0) {			//if image is open
   		     	imageName = getTitle();
				getDimensions(width, height, channels, slices, frames);
				if (channels > 1) {		//split channels or give new image name as if it was split
					run("Split Channels");
					} else {
					rename("C1-" + imageName);	
					}
				//get image tags (=subtitles)
				imageTags = newArray(channels);
				for (currentChannel = 1; currentChannel <= channels; currentChannel++) {
					//print(fileList[currentFile], "C" + currentChannel + "-" + imageName);
					selectWindow("C" + currentChannel + "-" + imageName);
					currentImageTag = getInfo("image.subtitle");
					currentImageTag = substring(currentImageTag,indexOf(currentImageTag," (")+1,indexOf(currentImageTag,")")+1);
					imageTags[currentChannel-1] = currentImageTag;
					//now make nicely viewable for user
					if (slices > 1) setSlice(slices/2);
					resetMinAndMax();
					//doCommand("Start Animation");
					}
				print("opened: ", fileList[currentFile], ", channels = ", channels);  //to log window
				Array.print(imageTags);
				if (manualMode) {
					Dialog.create("Manual mode!");  //enable use inveractivity
					Dialog.addCheckbox("Stay in manual mode?", manualMode);	//if checked macro will run automatically
					Dialog.addCheckbox("Skip image?", false);		//will not be saved if false
					for (currentChannel = 1; currentChannel <= channels; currentChannel++) imageSuffix[currentChannel-1] = Dialog.addString("Channel " + currentChannel + ", tag: " + imageTags[currentChannel-1], imageSuffix[currentChannel-1]);
					Dialog.addCheckbox("Use tags?", useTags);			//will use the image tage and not the suffix (=user entry)
					Dialog.addCheckbox("Save stack as single images?", saveImageSequence);			//will use the image tage and not the suffix (=user entry)
					Dialog.show();
					manualMode = Dialog.getCheckbox();
					skipImage = Dialog.getCheckbox();
					for (currentChannel = 1; currentChannel <= channels; currentChannel++) imageSuffix[currentChannel-1] = Dialog.getString();
					useTags = Dialog.getCheckbox();
					saveImageSequence = Dialog.getCheckbox();
					} 
				//now iterate through all channel and save as .tif using selected tags
				for (currentChannel = 1; currentChannel <= channels; currentChannel++) {
					selectWindow("C" + currentChannel + "-" + imageName);
					if (useTags) {							//define suffix
						suffix = "_" + imageTags[currentChannel-1];	
						} else {
						suffix = imageSuffix[currentChannel-1];
						}
					if (!skipImage) {						//if user skips file
						if (saveImageSequence) {
							run("Image Sequence... ", "format=TIFF name=&imageName&suffix save=&outputPath");
							print("saved image sequence:", imageName + suffix , "with", slices, "images");							
							} else {
							saveAs("Tiff", outputPath + imageName + suffix +  ".tif");
							//saveAs("Tiff", outputPath + substring(fileList[currentFile],0,lengthOf(fileList[currentFile])-4) + suffix +  ".tif");
							//print("saved:", substring(fileList[currentFile],0,lengthOf(fileList[currentFile])-4) + suffix +  ".tif");
							print("saved:", imageName + suffix + ".tif");
							}
						} else {
						print("file: ", fileList[currentFile], " skipped by user.");
						}
					close();
					}	
				} else {
				print("file: ", fileList[currentFile], " could not be opend."); 	//if open() error
				}
			saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");	
        	}  //for each field
		} else {
		print("file: ", fileList[currentFile], " was skipped."); 	//if not .lsm
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
////////		      	F U N C T I O N S			     	/////////////
/////////////////////////////////////////////////////////////////////////////////////////////

//function saves the log window in the given path
//example: saveLog("C:\\Temp\\Log_temp.txt");
function saveLog(logPath) {
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
saveAs("Text", logPath);
if (nImages > 0) selectWindow(currentWindow);
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////
