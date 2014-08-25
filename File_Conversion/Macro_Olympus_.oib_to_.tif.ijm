//Olympus_.oib_to_.tif
macroName = "Olympus_.oib_to_.tif";
macroDescription = "This macro imports .oib image files from Olympus microscope, splits channels and saves stack for each channel.";
//Macro uses Bioformats of Fiji
//
//first release 07-05-2014 by Martin Stöter (stoeter(at)mpi-cbg.de)
html = "<html>"
	+"<font color=red>" + macroName + " (release 2014-05-07)</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>http://idisk-srv1.mpi-cbg.de/knime/FijiUpdate/TDS_macros/" + macroName + ".htm</font> <br>"
	+"<font color=black>...get this URL from Log window!</font> <br>"
    	+"</font>";

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools by TDS@MPI-CBG)\n \n" + macroDescription + "\nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(html);
print("http://idisk-srv1.mpi-cbg.de/knime/FijiUpdate/TDS%20macros/" + macroName + ".htm");
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
print("Input:", inputPath, "\nOutput:", outputPath);

//set array variables
imageSuffix = newArray("_Ch1", "_Ch2", "_Ch3", "_Ch4", "_Ch5");  //reset array of default channel names
manualMode = true;
	
//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=75 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");

//////////////////             M A C R O   :   O L Y M P U S _ . O I B _ T O _ . T I F        /////////////////////////////// 
//get file list and well list
fileList = getFileList(inputPath);
Array.sort(fileList);

//go through all file
for (currentFile = 0; currentFile < fileList.length; currentFile++) {
	if (endsWith(fileList[currentFile],".oib")) {   //check if it is right file and handle error on open()
		IJ.redirectErrorMessages();
		run("Bio-Formats (Windowless)", "open=[" + inputPath + fileList[currentFile] + "] autoscale color_mode=Composite concatenate_series open_files open_all_series view=Hyperstack stack_order=XYCZT");
		if (nImages > 0) {			//if image is open
			getDimensions(width, height, channels, slices, frames);
			if (channels > 1) {		//split channels or give new image name as if it was split
				run("Split Channels");
				} else {
				rename("C1-" + fileList[currentFile]);	
				}
			//get image tags (=subtitles)
			imageTags = newArray(channels);
			for (currentChannel = 1; currentChannel <= channels; currentChannel++) {
				selectWindow("C" + currentChannel + "-" + fileList[currentFile]);
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
				Dialog.addCheckbox("Use tags?", false);			//will use the image tage and not the suffix (=user entry)
				Dialog.show();
				manualMode = Dialog.getCheckbox();
				skipImage = Dialog.getCheckbox();
				for (currentChannel = 1; currentChannel <= channels; currentChannel++) imageSuffix[currentChannel-1] = Dialog.getString();
				useTags = Dialog.getCheckbox();
				} else {
				imageSuffix = newArray("_Ch1", "_Ch2", "_Ch3", "_Ch4", "_Ch5");  //reset array of default channel names
				}
			//now iterate through all channel and save as .tif using selected tags
			for (currentChannel = 1; currentChannel <= channels; currentChannel++) {
				selectWindow("C" + currentChannel + "-" + fileList[currentFile]);
				if (useTags) {							//define suffix
					suffix = "_" + imageTags[currentChannel-1];	
					} else {
					suffix = imageSuffix[currentChannel-1];
					}
				if (!skipImage) {						//if user skips file
					saveAs("Tiff", outputPath + substring(fileList[currentFile],0,lengthOf(fileList[currentFile])-4) + suffix +  ".tif");
					print("saved:", substring(fileList[currentFile],0,lengthOf(fileList[currentFile])-4) + suffix +  ".tif");
					} else {
					print("file: ", fileList[currentFile], " skipped by user.");
					}
				close();
				}
			} else {
			print("file: ", fileList[currentFile], " could not be opend."); 	//if open() error
			}	
		} else {
		print("file: ", fileList[currentFile], " was skipped."); 	//if not .oib
		}
	}	
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////
