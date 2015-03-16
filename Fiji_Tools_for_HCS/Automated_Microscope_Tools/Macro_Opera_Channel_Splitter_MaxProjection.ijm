//Macro_Opera_Channel_Splitter_MaxProjection
macroName = "Opera_Channel_Splitter_MaxProjection";
macroShortDescription = "This macro splits channels from Opera microscope .flex images and does a maximum projection per channel.";
macroDescription = "This macro splits up to 5 channels per field acquired with Opera automated microscope and saves individual .tif." +
	"\nIf channels have multiple planes, a maximum Z-projection per channel is performed. Define channel tags for .tif." +
	"\nImage order: e.g. Ch1-z1, Ch1-z2, Ch1-z3, Ch2-z1, Ch2-z2, Ch2-z3, Ch3-z1, ...";
macroRelease = "first release 29-08-2014 by Marc Bickle and Martin Stöter (stoeter(at)mpi-cbg.de)";
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
print(macroName,"\nStart:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
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
imageSuffix = newArray("Ch1", "Ch2", "Ch3", "Ch4", "Ch5");  //array of default channel names
imageSuffix = newArray("ZO1", "CD13", "DAPI", "Ch4", "Ch5");
planesPerChannelArray = newArray(3, 3, 1, 1, 1);  //array of planes per channel
batchMode = false;
imageNumberPerField = 0;
numberOfChannels = 0;

//get file list and well list
fileList = getFileList(inputPath);
Array.sort(fileList);
while (!(numberOfChannels > 0 && numberOfChannels <= 5)) { //must be 1-5 channels
	Dialog.create("How many channels!");  //enable use inveractivity
	Dialog.addNumber("Number of channels in .flex?", 3);	//if checked macro will run automatically
	Dialog.show();
	numberOfChannels = Dialog.getNumber();
	}
	
Dialog.create("How many planes per channel");  //enable use inveractivity
for (currentChannel = 1; currentChannel <= numberOfChannels; currentChannel++) {
	Dialog.addNumber("Number of planes in channel " + currentChannel + ":", planesPerChannelArray[currentChannel-1]);	
}
for (currentChannel = 1; currentChannel <= numberOfChannels; currentChannel++) {
	Dialog.addString("Channel " + currentChannel + ", tag: ", imageSuffix[currentChannel-1]);	
}
Dialog.addCheckbox("Set batch mode (hide images)?", batchMode);	//if checke no images will be displayed
Dialog.show();
for (currentChannel = 1; currentChannel <= numberOfChannels; currentChannel++) {
	planesPerChannelArray[currentChannel-1] = Dialog.getNumber();
	imageNumberPerField = imageNumberPerField + planesPerChannelArray[currentChannel-1];
	}
for (currentChannel = 1; currentChannel <= numberOfChannels; currentChannel++) imageSuffix[currentChannel-1] = Dialog.getString();
batchMode = Dialog.getCheckbox();

setBatchMode(batchMode);
//go through all file
for (currentFile = 0; currentFile < fileList.length; currentFile++) {
	if (endsWith(fileList[currentFile],".flex")) {   //check if it is right file and handle error on open()
		showProgress(currentFile/fileList.length);
		showStatus("processing " + fileList[currentFile]);
		IJ.redirectErrorMessages();
		run("TIFF Virtual Stack...", "open=" + inputPath + fileList[currentFile]);
		showProgress(currentFile / fileList.length);
        showStatus("processing" + fileList[currentFile]);
        if (nImages > 0) {			//if image is open    	
			getDimensions(width, height, channels, slices, frames);
			//print(width, height, channels, slices, frames);
			print("opened (" + (currentFile + 1) + "/" + fileList.length + "):", fileList[currentFile], ", channels =", channels);  //to log window
			for (currentField = 1; currentField <= slices/imageNumberPerField; currentField++) {
				//now iterate through all channel and save as .tif using selected tags
				firstImageInChannel = 1;
				lastImageInChannel = 0;
				for (currentChannel = 1; currentChannel <= numberOfChannels; currentChannel++) {
					selectWindow(fileList[currentFile]);
					lastImageInChannel = lastImageInChannel + planesPerChannelArray[currentChannel-1];	
					//print(currentField,currentChannel,planesPerChannelArray[currentChannel-1],firstImageInChannel,lastImageInChannel);
					run("Make Substack...", "slices=" + ((currentField-1) * imageNumberPerField + firstImageInChannel) + "-" + ((currentField-1) * imageNumberPerField + lastImageInChannel));
					subStackID = getTitle();
					if (planesPerChannelArray[currentChannel-1] > 1) run("Z Project...", "start=1 stop=" + planesPerChannelArray[currentChannel-1] + " projection=[Max Intensity]");
					saveAs("Tiff", outputPath + substring(fileList[currentFile],0,9) + "_f" + currentField + "_" + imageSuffix[currentChannel-1] + ".tif");	
					print("saved substack (" + ((currentField-1) * imageNumberPerField + firstImageInChannel) + "-" + ((currentField-1) * imageNumberPerField + lastImageInChannel) + "):", substring(fileList[currentFile],0,9) + "_f" + currentField + "_" + imageSuffix[currentChannel-1] + ".tif");
					close();			//Z-projection
					close(subStackID);	//substack
					firstImageInChannel = firstImageInChannel + planesPerChannelArray[currentChannel-1];
					}
				}
			close(fileList[currentFile]);	//.flex
			} else { //if no images open
			print("file (" + (currentFile + 1) + "/" + fileList.length + "): ", fileList[currentFile], " could not be opened."); 	//if open() error
			}	
		} else { //if file has different extensionn
		print("file (" + (currentFile + 1) + "/" + fileList.length + "): ", fileList[currentFile], " was skipped."); 	//if not .lsm
		}
	}
		
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	
	
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////