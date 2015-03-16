//Macro_Opera_Stack_Montage_for_Fish
macroName = "Macro_Opera_Stack_Montage_for_Fish";
macroDescription = "This macro loads Opera images (.flex) and saves the montage of subsequent fields as .tif" +
	"\nThe macro can handle stacks and up to 4 channels" +
	"\nThis macro does optionally an autofluorescence substraction (Ch2-Ch3).";
release = "second release 14-10-2014 by Martin Stöter (stoeter(at)mpi-cbg.de)";
html = "<html>"
	+"<font color=red>" + macroName + "/n" + release + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>https://github.com/stoeter/Fiji-Tools-for-HCS/wiki/Macro-Opera-Stack-Montage-for-Fish</font> <br>"
	+"<font color=black>...get this URL from Log window!</font> <br>"
    	+"</font>";
//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName,"\nStart:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

resultSubfolders = newArray("rawtif", "Zmax", "RGB");  //folder names where to store result images
Array.concat(resultSubfolders,File.separator);		   //add OS specific fiel separator
for (i = 0; i < resultSubfolders.length; i++) {
	File.makeDirectory(outputPath + resultSubfolders[i]);
	if (!File.exists(outputPath + resultSubfolders[i]))
      exit("Unable to create directory");
}
	
availableImageFormats = newArray("Opera (.flex)");  //image formats to choose
Dialog.create("Conditions");
Dialog.addChoice("Image format:", availableImageFormats);
Dialog.addNumber("Zplanes", 8);
Dialog.addNumber("Fields:", 4);
Dialog.addNumber("Channels:", 3);
Dialog.addNumber("Rows of Montage:", 2);
Dialog.addNumber("Columns of Montage:", 2);
Dialog.addCheckbox("Do background subtraction?", true);
Dialog.addCheckbox("Rotate left?", true);
Dialog.addCheckbox("Subtract auto-fluorescence image?", true);
Dialog.addCheckbox("Save RGB?", true);
Dialog.show();
imageFormat = Dialog.getChoice();
numberOfZplanes = Dialog.getNumber();
numberOfFields = Dialog.getNumber();
numberOfChannels = Dialog.getNumber();
montageRow = Dialog.getNumber();
montageColumn = Dialog.getNumber();
bkgCorrection = Dialog.getCheckbox();
rotate = Dialog.getCheckbox();
subtractImage = Dialog.getCheckbox();
saveRGB = Dialog.getCheckbox();
//to log
print("Zplanes", numberOfZplanes, ", Fields:", numberOfFields, ", Channels:", numberOfChannels, "\nRows of Montage:", montageRow, ", Columns of Montage:", montageColumn, "\nDo background substraction?", 
	bkgCorrection,  ", Rotate left?", rotate, ", Subtract auto-fluorescence image?", subtractImage, ", Saves RGB?", saveRGB);

//set array variables for RGB merge
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4

//set variables for auto contrast and background corrections
bkgCorrValue = newArray(80, 80, 80, 80); 
if (bkgCorrection) {
	Dialog.create("Background substraction parameter (0 = not applied)");
	Dialog.addMessage("Background substraction\nRolling ball radius (0 = not applied)");
	for (i = 1; i <= numberOfChannels; i++) Dialog.addNumber(availableChannels[i], bkgCorrValue[i-1]);
	Dialog.show();
	for (i = 0; i < numberOfChannels; i++) {
		bkgCorrValue[i] = Dialog.getNumber();
		print(availableChannels[i+1], "rolling ball radius =", bkgCorrValue[i]);
		}
	}

availableChannelNumber = newArray(0,1,2,3); //array numbers for channel 1-4
availableChannelNumber = Array.trim(availableChannelNumber,numberOfChannels);
availableChannels = Array.trim(availableChannels,numberOfChannels+1);
//set variables for channel subtraction
if (subtractImage) {
	Dialog.create("Subtraction of auto-fluorescence image");
	Dialog.addChoice("Channel containing auto-fluorescence:", availableChannelNumber, "2");
	Dialog.addChoice("Channel from which to subtract auto-fluorescence:", availableChannelNumber, "1");
	Dialog.show();
	afChannelNumber = Dialog.getChoice();
	afSubtractionChannelNumber = Dialog.getChoice();
	print("Channel containing auto-fluorescence:", afChannelNumber, "will be subtracted from channel :", afSubtractionChannelNumber);
	}
/*set variables for RGB
if (saveRGB) {
	Dialog.create("How to merge RGB");
	for (i = 1; i <= 3; i++) Dialog.addChoice(availableRGBsettings[i], availableChannels, availableChannels[0]);
	if (subtractImage) availableChannels = Array.concat(availableChannels,"substracted");
	Dialog.show();
	RGBstring = "";
	for (i = 1; i <= 3; i++) {
		availableRGBsettings[i] = Dialog.getChoice();
		if (availableRGBsettings[i] != availableChannels[0]) RGBstring = RGBstring + "c" + i + "=MAX_" + availableRGBsettings[i];
		+ " ";
	}
	RGBstring = "c1=tempMAX_" + availableChannels[0 + 1] + " c2=tempMAX_" + availableChannels[1 + 1] + "substracted");
	Dialog.getChoice();

	
	afSubtractionChannelNumber = Dialog.getChoice();
	print("Channel containing auto-fluorescence:", afChannelNumber, "will be surbracted from channel :", afSubtractionChannelNumber);
	}

	setMinAndMax(8, 200);
	run("Merge Channels...", "c1=tempMAX_" + availableChannels[0 + 1] + " c2=tempMAX_" + availableChannels[1 + 1] + "substracted");
*/
	
//list files in directory
fileList = getFileList(inputPath);
l = fileList.length;
//setBatchMode(true);

//configure
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Options...", "iterations=1 count=1 black edm=Overwrite");
run("Close All");

wellList = getAllWellsFuntion(fileList, true);
exampleFileName = getImageFileExample(fileList);

//now load well-field by well-field and merge to RGB
for (currentWell = 0; currentWell < wellList.length; currentWell++) { //currentWell < wellList.length; 26-27
	//for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
	//currentChannel = parseInt(substring(channelsForRGBmerge[channels],lengthOf(channelsForRGBmerge[channels])-1,lengthOf(channelsForRGBmerge[channels])));  //get number of selected channel to be opened
	fileName = substring(exampleFileName,0,lengthOf(exampleFileName)-14) + wellList[currentWell] 
			+ substring(exampleFileName,lengthOf(exampleFileName)-8,lengthOf(exampleFileName)); 
	IJ.redirectErrorMessages();
	if (imageFormat == "Opera (.flex)") run("TIFF Virtual Stack...", "open=" + inputPath + fileName); 
	if (!(nImages>0)) print("well:", wellList[currentWell], ", file:", fileName, "could not be opened!"); //if no file was found
		else {
		//to log window
		print("well:", wellList[currentWell], ", file:", fileName);                         
		imageTitle = getTitle();
		run("Stack to Hyperstack...", "order=xyczt(default) channels=" + numberOfChannels + " slices=" + numberOfZplanes + " frames=" + numberOfFields + " display=Grayscale");
		run("Re-order Hyperstack ...", "channels=[Frames (t)] slices=[Slices (z)] frames=[Channels (c)]");
		run("Hyperstack to Stack");
		for(field = 0; field < numberOfZplanes; field++) {
			for(currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
			selectWindow(imageTitle);
			run("Make Substack...", "  slices=" + (((field)*numberOfFields+1)+(currentChannel*numberOfZplanes*numberOfFields)) + "-" + ((field+1)*numberOfFields)+(currentChannel*numberOfZplanes*numberOfFields));
			subStackTitle = getTitle();
			selectWindow(subStackTitle);
			if(bkgCorrection){
				run("Subtract Background...", "rolling=" + (bkgCorrValue[currentChannel]) + " stack");
				}
			run("Make Montage...", "columns=" + montageColumn + " rows=" + montageRow + " scale=1 first=1 last=" + montageRow * montageColumn + " increment=1 border=0 font=12");
			selectWindow("Montage");
			rename("Montage " + field);
			selectWindow(subStackTitle);
			close();
			}
		}	
		selectWindow(imageTitle);
		close(); 
		run("Images to Stack", "name=Stack title=[] use");
		run("Stack to Hyperstack...", "order=xyczt(default) channels=" + numberOfChannels + " slices=" + numberOfZplanes + " frames=1 display=Grayscale");
		imageTitle = getTitle();
		for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
			selectWindow(imageTitle);
			setSlice(currentChannel + 1);
			run("Reduce Dimensionality...", "  slices keep");
			rename(availableChannels[currentChannel + 1]);
		}
		selectWindow(imageTitle);  
		close();
			
		//### save the raw tif of each channel and Zmax projection ###
		for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
			selectWindow(availableChannels[currentChannel + 1]);
			if (rotate) run("Rotate 90 Degrees Left");
			saveAs("Tiff", outputPath + resultSubfolders[0] + wellList[currentWell] + "000_Ch" + (currentChannel + 1));
			print("Saved file:", wellList[currentWell] + "000_Ch" + (currentChannel + 1) + ".tif");
			rename(availableChannels[currentChannel + 1]);
			if(bkgCorrection) run("Subtract Background...", "rolling=" + (bkgCorrValue[currentChannel]) + " stack");
			run("Z Project...", "start=1 stop=" + numberOfZplanes + " projection=[Max Intensity]");	
			saveAs("Tiff", outputPath + resultSubfolders[1] + wellList[currentWell] + "000_Ch" + (currentChannel + 1) + "_Zmax.tif");
			rename("MAX_" + availableChannels[currentChannel + 1]);
			print("Saved file:", wellList[currentWell] + "000_Ch" + (currentChannel + 1) + "_Zmax.tif");
			//close();
			}		

		//### remove autofluorescence   ###
		///substract autofluorescence channel (here 2) from GFP channel (here 1)
		if (subtractImage) {
			selectWindow(availableChannels[afChannelNumber + 1]);
			run("Duplicate...", "title=" + availableChannels[afChannelNumber + 1] + "blurred duplicate range=1-" + numberOfZplanes);
			run("Gaussian Blur...", "sigma=1 stack");   //reduce influence of camera noise
			imageCalculator("Subtract create stack", availableChannels[afSubtractionChannelNumber + 1] , availableChannels[afChannelNumber + 1] + "blurred");
			rename(availableChannels[afSubtractionChannelNumber + 1] + "subtracted");
			if(bkgCorrection) run("Subtract Background...", "rolling=" + (bkgCorrValue[afSubtractionChannelNumber + 1]) + " stack");
			run("Z Project...", "start=1 stop=" + numberOfZplanes + " projection=[Max Intensity]");
			//save & tidy up
			saveAs("Tiff", outputPath + resultSubfolders[1] + wellList[currentWell] + "000_Ch" + (afSubtractionChannelNumber + 1) + "_subtracted_Zmax.tif");  //Zmax
			rename("MAX_" + availableChannels[afSubtractionChannelNumber + 1] + "subtracted");
			print("Saved file:", wellList[currentWell] + "000_Ch" + (1 + 1) + "_subtracted_Zmax.tif");
			run("Enhance Contrast", "saturated=0.35");
			run("8-bit");
			selectWindow(availableChannels[afChannelNumber + 1] + "blurred");
			close();
			selectWindow(availableChannels[afSubtractionChannelNumber + 1] + "subtracted");
			saveAs("Tiff", outputPath + resultSubfolders[0] + wellList[currentWell] + "000_Ch" + (afSubtractionChannelNumber + 1) + "_subtracted.tif"); //rawtif
			print("Saved file:", wellList[currentWell] + "000_Ch" + (afSubtractionChannelNumber + 1) + "_subtracted.tif");
			close();
			selectWindow("MAX_" + availableChannels[afSubtractionChannelNumber + 1] + "subtracted");
			}
			
		//tidy up raw
		for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
			selectWindow(availableChannels[currentChannel + 1]);
			close();
			}

		if (saveRGB) {			
			selectWindow("MAX_" + availableChannels[0 + 1]);
			//getStatistics(area, mean, min, max, std, histogram);
			//print(area, mean, min, max, std);
			setMinAndMax(4, 100);
			selectWindow("MAX_" + availableChannels[afSubtractionChannelNumber + 1] + "substracted");
			setMinAndMax(8, 200);
			if (saveRGB) RGBmergeString = "c1=MAX_" + availableChannels[0 + 1] + " c2=MAX_" + availableChannels[afSubtractionChannelNumber + 1] + "substracted");
				else RGBmergeString = "c1=MAX_" + availableChannels[0 + 1] + " c2=MAX_" + availableChannels[afSubtractionChannelNumber + 1]);
			run("Merge Channels...", RGBmergeString);
			saveAs("PNG", outputPath + resultSubfolders[2] + wellList[currentWell] + "000_RGB.tif");
			}
		run("Close All");	
		}
	}		//file open was successful
	
//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");

/////////////////////////////////////////////////////////////////////////////////////////////
////////			F U N C T I O N S				/////////////
/////////////////////////////////////////////////////////////////////////////////////////////
function getAllWellsFuntion(fileList, closeWindow) {
//function get all unique wells from a file list
//the file list needs to be a list of files from Opera (.flex)
//the function goes through the sorted list and finds the well-text in file name (e.g. 002003000.flex => row 002, column 003 => B3)
//unique well-text and number of found files per well are put to a list/array
//message pops up information about number of wells found and their number of images, that will be closed then second parameter = true
Array.sort(fileList);
wellList = newArray(fileList.length);
wellImageCountList = newArray(fileList.length);
wellIndexList = newArray(fileList.length);
wellIndex = 0;
wellImageCount = 0;
currentFile = 0;
if (imageFormat == "Opera (.flex)") {
	do {
		if (endsWith(fileList[currentFile],".flex")){ //exclude metadata files
			wellImageCount++;
			if (wellIndex == 0) {  //for first image found set current well
				currentWell = substring(fileList[currentFile],lengthOf(fileList[currentFile])-14,lengthOf(fileList[currentFile])-8);
				wellList[wellIndex] = currentWell;
				wellIndexList[wellIndex] = d2s(wellIndex+1,0);
				wellIndex++;
				}
			//check if next image belongs to same well, if not put well and counted field-channel images in list
			if (currentWell != substring(fileList[currentFile],lengthOf(fileList[currentFile])-14,lengthOf(fileList[currentFile])-8)) {
				wellImageCountList[wellIndex-1] = d2s(wellImageCount-1,0);   //write how many images in current well
				wellImageCount = 1;                                 //reset counter
				currentWell = substring(fileList[currentFile],lengthOf(fileList[currentFile])-14,lengthOf(fileList[currentFile])-8);
				wellList[wellIndex] = currentWell;                  //set new current well 
				wellIndexList[wellIndex] = d2s(wellIndex+1,0);
				wellIndex++;			
				}
			//for debugging: print(fileList[currentFile], currentFile, currentWell, wellIndex, wellImageCount); 	
			}
		currentFile++;
		} while (currentFile < fileList.length); //for all files found
		if (wellIndex == 0) print("No " + imageFormat + " files found.");
			else wellImageCountList[wellIndex-1] = d2s(wellImageCount,0);                    //write how many imges are in last well
	}
	
//trim array lists and show in window
wellList = Array.slice(wellList,0,wellIndex);
wellIndexList = Array.slice(wellIndexList,0,wellIndex);
wellImageCountList = Array.slice(wellImageCountList,0,wellIndex);
//show result of well list
Array.show(wellIndexList,wellList,wellImageCountList);
waitForUser("Number of well found: " + wellIndex + "\n " + " \n" +"Check if number of wells and number of images in well" + "\n" + "are as expected! Otherwise press 'ESC' and check image list!");
//tidy up and close windows
if (closeWindow) {
	windowList = getList("window.titles");
	for (i = 0; i < windowList.length; i++) {
		if (windowList[i] == "Arrays") {
			selectWindow("Arrays");
			run("Close");
			}
		}
	}
//end of function: return well list
return wellList;
}
/////////////////////////////////////////////////////////////////////////////////////////////////
function getImageFileExample(fileList) {
//function get an image file name as an example from a file list
//the file list needs to have image file name with these extensions: .flex
//message pops up if no image is found and macro is aborted
currentFile = 0;
if (imageFormat == "Opera (.flex)") {
	do {
		if (endsWith(fileList[currentFile],".flex")){ //exclude metadata files
			//end of function: first image name
			return fileList[currentFile];
			}
		currentFile++;
		} while (currentFile < fileList.length); //for all files found
	}
//show file list and abort macro
Array.show(fileList);
exit("No image files found!?" + "\n " + " \n" +"Check image list!");
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////
