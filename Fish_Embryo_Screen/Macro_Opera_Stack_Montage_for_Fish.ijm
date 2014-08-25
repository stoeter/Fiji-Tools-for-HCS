//Macro_Opera_Stack_Montage_for_Fish
macroName = "Macro_Opera_Stack_Montage_for_Fish";
macroDescription = "This macro loads Opera images (.flex) and saves the montage of subsequent fields as .tif" +
	"\nThe macro can handle stacks and up to 4 channels" +
	"\nCurrently the macro does additionally a autofluorescence substraction (Ch2-Ch3)..";
release = "first release 01-02-2014 by Martin Stöter (stoeter(at)mpi-cbg.de)";
html = "<html>"
	+"<font color=red>" + macroName + "/n" + release + "</font> <br>"
	+"<font color=black>Check for help on this web page:</font> <br>"
	+"<font color=blue>http://idisk-srv1.mpi-cbg.de/knime/FijiUpdate/" + macroName + ".htm this is under construction</font> <br>"
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

availableImageFormats = newArray("Opera (.flex)", "Exported (.tif)", "ArrayScan (.c01)");  //image formats to choose
resultSubfolders = newArray("rawtif\\", "Zmax\\", "RGB\\");  //folder names where to store result images

Dialog.create("Conditions");
Dialog.addChoice("Image format:", availableImageFormats);
Dialog.addNumber("Zplanes", 8);
Dialog.addNumber("Fields:", 4);
Dialog.addNumber("Channels:", 3);
Dialog.addNumber("Rows of Montage:", 2);
Dialog.addNumber("Columns of Montage:", 2);
Dialog.addNumber("Binning:", 2);
Dialog.addCheckbox("Do background substraction?", true);
Dialog.addCheckbox("Do smoothing?", false);
Dialog.addCheckbox("Rotate left?", true);

Dialog.show();
imageFormat = Dialog.getChoice();
numberOfZplanes = Dialog.getNumber();
numberOfFields = Dialog.getNumber();
numberOfChannels = Dialog.getNumber();
montageRow = Dialog.getNumber();
montageColumn = Dialog.getNumber();
binning  = Dialog.getNumber();
bkgCorrection = Dialog.getCheckbox();
smoothing = Dialog.getCheckbox();
rotate = Dialog.getCheckbox();
//to log
print("Zplanes", numberOfZplanes, ", Fields:", numberOfFields, ", Channels:", numberOfChannels, "\nRows of Montage:", montageRow, ", Columns of Montage:", montageColumn, ", Binning:", binning, "\nDo background substraction?", bkgCorrection, ", Do smoothing?", smoothing , ", Rotate left?", rotate);

//set array variables for RGB merge
availableChannels = newArray("*None*", "Channel_0", "Channel_1", "Channel_2", "Channel_3");  //array of color selection for channel 1-4
zMaxProjection =newArray(numberOfChannels);
zMaxProjectionBlurred =newArray(numberOfChannels);

//set variables for auto contrast and background corrections
bkgCorrValue = newArray(80, 80, 80, 80); 
if (bkgCorrection) {
	Dialog.create("Background substraction parameter (0 = not applied)");
	Dialog.addMessage("Background substraction\nRolling ball radius (0 = not applied)");
	for (i = 1; i <= numberOfChannels; i++) Dialog.addNumber(availableChannels[i], bkgCorrValue[i-1]);
	Dialog.show();
	for (i = 0; i < numberOfChannels; i++) {
		bkgCorrValue[i] = Dialog.getNumber();
		print(availableChannels[i+1], bkgCorrValue[i]);
		}
	}

//list files in directory
fileList = getFileList(inputPath);
l = fileList.length;
//setBatchMode(true);

//configure
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=75 gif=-1 file=.txt copy_column copy_row save_column save_row");	
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
	//to log window
	print("well:", wellList[currentWell], ", file:", fileName);
	if (imageFormat == "Opera (.flex)") run("TIFF Virtual Stack...", "open=" + inputPath + fileName);                           
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
		if(smoothing == 1){
			run("Mean...", "radius=1 stack");
			}
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
		
	//### save the raw tif of each channel, scattered light artefact, crop and Zmax projection ###
	//then apply the insideWellMask to remove scattered light artifact
	//crop image to remove 0 intensity problem with autothresholing and substract the background 
	for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
		selectWindow(availableChannels[currentChannel + 1]);
		if (rotate) run("Rotate 90 Degrees Left");
		saveAs("Tiff", outputPath + resultSubfolders[0] + wellList[currentWell] + "000_Ch" + (currentChannel + 1));
		print("Saved file:", wellList[currentWell] + "000_Ch" + (currentChannel + 1) + ".tif");
		rename(availableChannels[currentChannel + 1]);
		if(bkgCorrection) run("Subtract Background...", "rolling=" + (bkgCorrValue[currentChannel]) + " stack");
		run("Z Project...", "start=1 stop=" + numberOfZplanes + " projection=[Max Intensity]");
		}

	//### remove autofluorescence   ###
	///substract autofluorescence channel (2) from GFP channel (1)
	selectWindow(availableChannels[2 + 1]);
	run("Duplicate...", "title=" + availableChannels[2 + 1] + "blurred duplicate range=1-" + numberOfZplanes);
	run("Gaussian Blur...", "sigma=1 stack");
	imageCalculator("Subtract create stack", availableChannels[1 + 1] , availableChannels[2 + 1] + "blurred");
	rename(availableChannels[1 + 1] + "substracted");
	if(bkgCorrection) run("Subtract Background...", "rolling=" + (bkgCorrValue[1 + 1]) + " stack");
	run("Z Project...", "start=1 stop=" + numberOfZplanes + " projection=[Max Intensity]");

	//tidy up
	for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
		selectWindow(availableChannels[currentChannel + 1]);
		close();
		}
	selectWindow(availableChannels[2 + 1] + "blurred");
	close();
	selectWindow(availableChannels[1 + 1] + "substracted");
	saveAs("Tiff", outputPath + resultSubfolders[0] + wellList[currentWell] + "000_Ch2_substracted.tif");
	print("Saved file:", wellList[currentWell] + "000_Ch2_substracted.tif");
	close();

	selectWindow("MAX_" + availableChannels[1 + 1] + "substracted");
	run("Duplicate...", "title=tempMAX_" + availableChannels[1 + 1] + "substracted");	//make temp image for RGB
	selectWindow("MAX_" + availableChannels[1 + 1] + "substracted");
	saveAs("Tiff", outputPath + resultSubfolders[1] + wellList[currentWell] + "000_Ch2_substracted_Zmax.tif");
	rename("MAX_" + availableChannels[1 + 1] + "substracted");
	print("Saved file:", wellList[currentWell] + "000_Ch" + (1 + 1) + "_substracted_Zmax.tif");
	rename("MAX_" + availableChannels[1 + 1] + "substracted");
	run("Enhance Contrast", "saturated=0.35");
	run("8-bit");
	close();

	selectWindow("MAX_" + availableChannels[0 + 1]);
	run("Duplicate...", "title=tempMAX_" + availableChannels[0 + 1]);	//make temp image for RGB
	setMinAndMax(4, 100);
	selectWindow("tempMAX_" + availableChannels[1 + 1] + "substracted");
	//getStatistics(area, mean, min, max, std, histogram);
	//print(area, mean, min, max, std);
	setMinAndMax(8, 200);
	run("Merge Channels...", "c1=tempMAX_" + availableChannels[0 + 1] + " c2=tempMAX_" + availableChannels[1 + 1] + "substracted");
	saveAs("PNG", outputPath + resultSubfolders[2] + wellList[currentWell] + "000_RGB.tif");
	close();

	//tidy up
	for (currentChannel = 0; currentChannel < numberOfChannels; currentChannel++) {
		selectWindow("MAX_" + availableChannels[currentChannel + 1]);
		saveAs("Tiff", outputPath + resultSubfolders[1] + wellList[currentWell] + "000_Ch" + (currentChannel + 1) + "_Zmax.tif");
		print("Saved file:", wellList[currentWell] + "000_Ch" + (currentChannel + 1) + "_Zmax.tif");
		close();
		}
	}
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
//the file list needs to be a list of files exported from ArrayScan/HCSView (.tif or .TIF)
//the function goes through the sorted list and finds the well-text in file name (MFGTMP_131004100001_C02f00d1.TIF position 12 to 9 counted form end of file name => C02)
//unique well-text and number of found images per well (fields x channels) are put to a list/array
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
		wellImageCountList[wellIndex-1] = d2s(wellImageCount,0);                    //write how many imges are in last well
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
//the file list needs to have image file name with these extensoins: .tif or .TIF
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
