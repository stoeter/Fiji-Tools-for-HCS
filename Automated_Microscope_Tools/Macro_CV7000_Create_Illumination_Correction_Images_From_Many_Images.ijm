//Create_Illumination_Correction_Images
//_From_Many_Images
macroName = "Create_Illumination_Correction_Images_From_Many_Images";
macroShortDescription = "This macro creates images for illumination correction from many images.";
macroDescription = "This macro many reads images (CV7000, tif) of a measurement and does z-projections." +
	"<br>Average and median z-projection will be calculated and saved." +
	"<br>A Gaussian blured image will be saved as well as an intenstiy profile plot from top-left to bottom-right corner of the image." +
	"<br>Optionally a dark field value can be subtracted." +
	"<br>Created images could be used for illumination corection for the CV7000 images.";
macroRelease = "second release 16-08-2016 by Martin Stoeter (stoeter(at)mpi-cbg.de)";
macroHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki/Macro-" + macroName;
macroHtml = "<html>" 
	+"<font color=red>" + macroName + "\n" + macroRelease + "</font> <br> <br>"
	+"<font color=black>" + macroDescription + "</font> <br> <br>"
	+"<font color=black>Check for more help on this web page:</font> <br>"
	+"<font color=blue>" + macroHelpURL + "</font> <br>"
	+"<font color=black>...get this URL from Log window!</font>"
    +"</font>";
    	
//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName,"\nStart:",year+"-"+month+"	-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
print(macroHelpURL);

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
run("Set Measurements...", "area mean standard min integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//define variables 
listOfChannel = newArray(1,2,3,4);
userRegEx = "(C01.tif)";
channelTag = "_C01"; 
imageSetTag = "_all";
gaussianRadius = 200;
gaussianTag = "_GBlur";
applyDarkFieldCorrected = true;
darkFieldValue = 100;

//define variables for image number restriction
restrictImageNumber = false;
totalImageNumber=100;
startingImageNumber=1;
imageIncrement=1;

Dialog.create("How many channels to analyse?");  
Dialog.addChoice("How many channels to analyse?", newArray("1","2","3","4"), 1); //up to 4 channels
Dialog.addString("Tag for projection image:", imageSetTag);
Dialog.addNumber("Apply Gaussian blur (radius: 0 = none):", gaussianRadius);
Dialog.addString("Tag for Gaussian blured image:", gaussianTag);
Dialog.addCheckbox("Apply dark field subtraction?", applyDarkFieldCorrected);	
Dialog.addNumber("Subtract intensity as dark field:", darkFieldValue);
Dialog.show();
numberOfChannels = Dialog.getChoice();	
imageSetTag = Dialog.getString();	
gaussianRadius = Dialog.getNumber();	
gaussianTag = Dialog.getString();	
applyDarkFieldCorrected= Dialog.getCheckbox();
darkFieldValue = Dialog.getNumber();	

channelTags = newArray(numberOfChannels);
userRegExs = newArray(numberOfChannels);
Dialog.create("Configure channels search..."); 
Dialog.addMessage("Define the files to be processed:");
for (i = 0; i < numberOfChannels; i++) {
	Dialog.addString("Channel " + (i + 1) + " tag: ", "_C0" + (i + 1));	
	Dialog.addString("Channel " + (i + 1) + " regex: ", "(C0" + (i + 1) + ".tif)");	
	}
Dialog.addCheckbox("Restrict number of image?", restrictImageNumber);	//if check file lists will be displayed
Dialog.show();
for (i = 0; i < numberOfChannels; i++) {
	channelTags[i] = Dialog.getString();	
	userRegExs[i] = Dialog.getString();	
	}
restrictImageNumber = Dialog.getCheckbox();

if (restrictImageNumber) {
	Dialog.create("Set image number restrictions:");
	Dialog.addMessage("Set image number restrictions:");
	Dialog.addNumber("Set starting image:", startingImageNumber);
	Dialog.addNumber("Set increment number:", imageIncrement);
	Dialog.addNumber("Set total image number to consider:", totalImageNumber);
	Dialog.show();
	startingImageNumber = Dialog.getNumber();	
	imageIncrement =  Dialog.getNumber();
	totalImageNumber = Dialog.getNumber();
	}

//print settings to log...
print("Number of channels =", numberOfChannels, "; tag for image set =", imageSetTag, "; Gaussian radius =", gaussianRadius, "; Gaussion tag for file =", "; is dark field correction appied?", applyDarkFieldCorrected, "; darkfield correction value =", darkFieldValue);
if (restrictImageNumber) { 
	print("starting image =", startingImageNumber, "increment number =", imageIncrement, "total image number to consider = ", totalImageNumber);
	} else {
	print("no image number restrictions");	
	}
for (i = 0; i < numberOfChannels; i++) print(channelTags[i] + " :", userRegExs[i]);

//start iteration through all channels
for (channel = 0; channel < numberOfChannels; channel++) {
	if (restrictImageNumber) {
		run("Image Sequence...", "open=" + inputPath + " number=&totalImageNumber starting=&startingImageNumber increment=&imageIncrement file=" + userRegExs[channel] + " sort");
		} else {
		run("Image Sequence...", "open=" + inputPath + " file=" + userRegExs[channel] + " sort");  //open all image fitting regex
		}
	stackImage = getTitle();
	getDimensions(width, height, channels, slices, frames);
	stackSize = slices;
	print("opened", stackSize,"images as:", stackImage);

	//start the z projection AVERAGE
	print("...doing average projection...");
	run("Z Project...", "projection=[Average Intensity]");
	saveAs("Tiff", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + ".tif");
	print("saved:", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + ".tif");
	
	//make Gaussion blurred image that can be used for CV7000 post-prosessing
	if (applyDarkFieldCorrected) run("Subtract...", "value=" + darkFieldValue);
	run("Gaussian Blur...", "sigma=" + gaussianRadius);
	getStatistics(area, mean, min, max);
	run("Multiply...", "value=" + (10000 / max));
	print("maximun intensity is:",max, "-> image is multiplied with", (10000 / max), " to normalize intensity to 10000.");
	resetMinAndMax();
	saveAs("Tiff", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + gaussianTag + gaussianRadius + ".tif");
	print("saved:", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + gaussianTag + gaussianRadius + ".tif");
	
	//make plot to visualize the shading
	makeLine(1, 1, width, height);
	run("Plot Profile");
	saveAs("PNG", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + gaussianTag + gaussianRadius + "_plot" + ".png");
	print("saved:", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + gaussianTag + gaussianRadius + "_plot" + ".png");
	
	//tidy up
	close(stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + gaussianTag + gaussianRadius + "_plot" + ".png");
	close(stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_AVG" + gaussianTag + gaussianRadius + ".tif");
	close(stackImage + imageSetTag + "_" + slices + channelTags[channel] + "_AVG" + ".tif");
	
	//start the z projection MEDIAN 
	selectWindow(stackImage);
	print("...doing median projection...");
	run("Z Project...", "projection=Median");
	//make 16-bit image, after median porjection this is 32-bit
	setMinAndMax(0, 65535);
	run("16-bit");
	resetMinAndMax();
	saveAs("Tiff", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + ".tif");
	print("saved:", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + ".tif");
	
	//make Gaussion blurred image that can be used for CV7000 post-prosessing
	if (applyDarkFieldCorrected) run("Subtract...", "value=" + darkFieldValue);
	run("Gaussian Blur...", "sigma=" + gaussianRadius);
	getStatistics(area, mean, min, max);
	run("Multiply...", "value=" + (10000 / max));
	print("maximun intensity is:",max, "-> image is multiplied with", (10000 / max), " to normalize intensity to 10000.");
	resetMinAndMax();
	saveAs("Tiff", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + gaussianTag + gaussianRadius + ".tif");
	print("saved:", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + gaussianTag + gaussianRadius + ".tif");
	
	//make plot to visualize the shading
	makeLine(1, 1, width, height);
	run("Plot Profile");
	saveAs("PNG", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + gaussianTag + gaussianRadius + "_plot" + ".png");
	print("saved:", outputPath + stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + gaussianTag + gaussianRadius + "_plot" + ".png");
	
	//tidy up
	close(stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + gaussianTag + gaussianRadius + "_plot" + ".png");
	close(stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + gaussianTag + gaussianRadius + ".tif");
	close(stackImage + imageSetTag + "_" + d2s(slices,0) + channelTags[channel] + "_MED" + ".tif");
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
	close(stackImage);
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

//function saves the log window in the given path
//example: saveLog("C:\\Temp\\Log_temp.txt");
function saveLog(logPath) {
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
saveAs("Text", logPath);
if (nImages > 0) selectWindow(currentWindow);
}
