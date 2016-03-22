//CV7000-Image-Stitcher
macroName = "CV7000-Image-Stitcher";
macroShortDescription = "This macro open CV7000 images of a well and stitched thme into one image.";
macroDescription = "This macro reads single CV7000 images of a well as .tif ." +
	"<br>The chosen folder will be searched for images including subfolders." +
	"<br>All images and channels of a well are stiched." +
	"<br>Current restrictions: C01.tif is BF channel, up to 2 fluoresent channels, no choice of color.";
macroRelease = "fifth release 21-03-2016 by Martin Stoeter (stoeter(at)mpi-cbg.de)";
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
//var inputPath = "Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\";
//var outputPath = "C:\\Users\\stoeter\\Desktop\\TestDeleteFolder\\"; 
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");
printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//set temp directory for saving images for stiching
tempPath = getDirectory("temp");
tempPath = tempPath + "Fiji_Temp_Folder_Stitching" + File.separator;
//check if temp foler is ok/empty
if (File.exists(tempPath)) {
	filesInTempFolder = getFileList(tempPath);
	if (filesInTempFolder.length > 0) {
		print("temp path:", tempPath);
		Dialog.create("Temp folder is not empty!")
		Dialog.addMessage("Delete all files from this temp folder:\n \n" + tempPath + "\n \n...and restart macro!");
		Dialog.show(); 
		exit();
		}
	} else {
	File.makeDirectory(tempPath);
	if (!File.exists(tempPath)) {
		print("temp path:", tempPath, "could not be generated! Please generate this temp folder manually!");
		Dialog.create("Temp folder not found!")
		Dialog.addMessage("Temp folder could not be generated. Create folder manually:\n \n" + tempPath + "\n \n...and restart macro!");
		Dialog.show(); 
		exit();
		}
	}

//check for bean shell and initialze setting of x- and y-overlap separately
print("setting up beanshell command to use  x- and y-overlap separately...");
if (eval("bsh", "plugin.Stitching_Grid.seperateOverlapY = true;") == false) {
	print("Beanshell plugin was installed. Please restart Fiji and macro...");
	Dialog.create("Beanshell plugin was installed!")
	Dialog.addMessage("Please restart Fiji and macro...");
	Dialog.show(); 
	exit();
	}  

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
//run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
//set array variables
var fileExtension = ".tif";                                                  //pre-definition of extension
var filterStrings = newArray("back","_A01_","");                                      //pre-definition of strings to filter
var availableFilterTerms = newArray("no filtering", "include", "exclude");   //dont change this
var filterTerms = newArray("exclude", "include", "no filtering");  //pre-definition of filter types 
var displayFileList = false;                                                 //shall array window be shown? 
setDialogImageFileFilter();
print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

//set variables for stiching
reverseOrder = false;
RGBstitch = true;
blurImage = true;
substractBackground = true;
saveAsGreyStack = true;
invertBFforTIF = false;
invertBFforPNG = true;
BFchannel = 3;
batchMode = false;
Dialog.create("How to stich the images?");
Dialog.addCheckbox("Subtract background before stitching?", substractBackground);	//if checked background will be subtracted
Dialog.addCheckbox("Blur images before stitching?", blurImage);	//if checked Gaussian blur with radius = 0.8 will applied before subtraction to reduce camera noise
Dialog.addCheckbox("Merge channels and stich as RGB?", RGBstitch);	//if checked files will be merged as RGB (with auto-contrast) before stiching (channels fixed to each other)
Dialog.addCheckbox("Reverse order for first-channel stitching?", reverseOrder);	//if checked loaded file list will be reverse and images will be merged based on last image
Dialog.addCheckbox("Save merged channels as grey stack?", saveAsGreyStack);	//if checked merged stiched images are saved as grey stack .tif
Dialog.addCheckbox("Invert brightfield image for .tif?", invertBFforTIF);	//if checked bright field imgage (C01.tif) will be inverted (then dark background).
Dialog.addCheckbox("Invert brightfield image for .png?", invertBFforPNG);	//if checked bright field imgage (C01.tif) will be inverted (then dark background).
Dialog.addNumber("Brightfield is in RGB channel:", BFchannel);	 //which channel is bright field
Dialog.addCheckbox("Switch of image display?", batchMode);	//if checked batch mode prevents image display
Dialog.show();
substractBackground = Dialog.getCheckbox();
blurImage = Dialog.getCheckbox();
RGBstitch = Dialog.getCheckbox();
reverseOrder = Dialog.getCheckbox();
saveAsGreyStack = Dialog.getCheckbox();
invertBFforTIF = Dialog.getCheckbox();
invertBFforPNG = Dialog.getCheckbox();
BFchannel = Dialog.getNumber();
batchMode = Dialog.getCheckbox();
print("subtract background:", substractBackground, "\nblur image:", blurImage, "\nused RGB for stiching:", RGBstitch, "\nreverse order of channel for stiching:", reverseOrder, "\n.tif saved as grey stack:", saveAsGreyStack , "\nbright field image inverted [.tif, .png, RGB channel]:", invertBFforTIF, invertBFforPNG, BFchannel, "\nbatch mode:", batchMode);

//configure stitching algorithm
stitchGridX = 2;
stitchGridY	= 3;
stitchOverlapX = 10;
stitchOverlapY = 30;
stitchRegThres = 0.10; 
stitchMaxDispThres = 2.50; 
stitchAbsDispThres = 3.50;
Dialog.create("Set stitching parameters");
Dialog.addNumber("Number of images in x:", stitchGridX);	//set number of images in one row
Dialog.addNumber("Number of images in y:", stitchGridY);	//set number of imgages in one column
Dialog.addNumber("% overlap of images in x:", stitchOverlapX);	//set overlap of images in x-direction as % of image
Dialog.addNumber("% overlap of images in y:", stitchOverlapY);	//set overlap of images in x-direction as % of image
Dialog.addNumber("Regression threshold:", stitchRegThres);	//set regression threshold, see here: http://fiji.sc/Stitching
Dialog.addNumber("Max/avg displacement threshold:", stitchMaxDispThres);	//see here: http://fiji.sc/Stitching
Dialog.addNumber("Absolute displacement threshold:", stitchAbsDispThres);	//see here: http://fiji.sc/Stitching
Dialog.show();
stitchGridX = Dialog.getNumber();
stitchGridY	= Dialog.getNumber();
stitchOverlapX = Dialog.getNumber();
stitchOverlapY = Dialog.getNumber();
stitchRegThres = Dialog.getNumber();
stitchMaxDispThres = Dialog.getNumber();
stitchAbsDispThres = Dialog.getNumber();
print("number of images in x:", stitchGridX, "\nnumber of images in y:", stitchGridY, "\noverlap of image in x:", stitchOverlapX, "\noverlap of image in y:", stitchOverlapY, "\nregression threshold:", stitchRegThres, "\nmax/avg displacement threshold:", stitchMaxDispThres, "\nabsolute displacement threshold:", stitchAbsDispThres);

//get file list ALL
fileList = getFileListSubfolder(inputPath, displayFileList);  //read all files in subfolders
fileList = getFileType(fileList, fileExtension, displayFileList);
fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings
//filterStrings = newArray("9MLG","back","");
//filterTerms = newArray("include", "exclude", "no filtering"); 
//fileList = getFilteredFileList(fileList, false, false);  

wellList = getUniqueWellListCV7000(fileList, displayFileList);
wellFieldList = getUniqueWellFieldListCV7000(fileList, displayFileList);
fieldList = getUniqueFieldListCV7000(fileList, displayFileList);
channelList = getUniqueChannelListCV7000(fileList, displayFileList);

//waitForUser("Do you really want to open " + fileList.length + " files?" + "\n\n" + "Otherwise press 'ESC' and check image list and filter text!");
setBatchMode(batchMode);

//set variables according to user dialogs
contrastValueArray = newArray(61000,65535,20,800,20,300,0,100,0,100);  //vector of alternating min-max contrast values => newArray(ch1-min,ch1-max,ch2-min,ch2-max,ch3-min, ...)
fileEndArray = newArray("C01.tif","C02.tif","C03.tif");  //vector of a file endings of individual channels
channelToRGBArray = newArray(3,2,1);   //vector of colors (RGB channel numbers) assigned to file endings
bkgValueSubstractionArray = newArray(50,20,20);   //vector of background subtraction values / radia
if (true) {
	fileTag = "_RGB";
	Dialog.create("Set contrast values for RGB merge");
	Dialog.addMessage("Red = 1, Green = 2, Blue = 3");
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {
		Dialog.addMessage("--------------------------------------------");
		Dialog.addNumber("Color of channel ends with " + fileEndArray[currentChannel] + ":", channelToRGBArray[currentChannel]);	 //which channel is which color in RGB
		Dialog.addNumber("Background subtraction radius " + channelList[currentChannel] + ":", bkgValueSubstractionArray[currentChannel]);	 //which channel i
		Dialog.addNumber("Set minimum intensity channel " + channelList[currentChannel] +":", contrastValueArray[currentChannel * 2]);	//set value for min
		Dialog.addNumber("Set maximum intensity channel " + channelList[currentChannel] +":", contrastValueArray[currentChannel * 2 + 1]);	//set value for max
		}
	Dialog.show();
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {
		channelToRGBArray[currentChannel] = Dialog.getNumber();
		bkgValueSubstractionArray[currentChannel] = Dialog.getNumber();
		contrastValueArray[currentChannel * 2] = Dialog.getNumber();
		contrastValueArray[currentChannel * 2 + 1]  = Dialog.getNumber();
		print("channel " + channelList[currentChannel] + ": ends with", fileEndArray[currentChannel], "is assigned to RGB channel", channelToRGBArray[currentChannel] + "; bkg subtraction =", bkgValueSubstractionArray[currentChannel] + ", contrast min =", contrastValueArray[currentChannel * 2], "and max =", contrastValueArray[currentChannel * 2 + 1]);  
		}
	} else {
	fileTag = "_allCh";
	}
	
print("===== starting processing.... =====");
//go through all files

for (currentWell = 0; currentWell < wellList.length; currentWell++) {   // well by well
	skipWell = false;
	mergeChannelString = "";
	for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel per well
		//define new filters and filter file list for currentWell and currentChannel
		filterStrings = newArray("_" + wellList[currentWell] + "_" ,channelList[currentChannel] + ".tif","");      //pre-definition of strings to filter, add "_" because well strings e.g. A03, L01, C02 can be in file name at other places, e.g ..._A06_T0001F001L01A03Z01C02.tif and ".tif" to excluse well C02 instead of channel C02
		filterTerms = newArray("include", "include", "no filtering");  //pre-definition of filter types 
		wellChannelFileList = getFilteredFileList(fileList, false, false);
		if (wellChannelFileList.length != fieldList.length) skipWell = true;
		//now open all files (wellChannelFileList) that belong to one wellField in all channels
		firstImage = "";
		fileName = "";
		for (currentFile = 0; currentFile < wellChannelFileList.length; currentFile++) {
			//image sequence & regEx would be possible, but it seems to be slow: run("Image Sequence...", "open=Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\ file=(_B03_.*C01) sort");
			IJ.redirectErrorMessages();
			open(wellChannelFileList[currentFile]);
			currentImage = getTitle();
			showProgress(currentFile / wellChannelFileList.length);
	       	showStatus("processing" + fileList[currentFile]);
			print("opened (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
			//image is open, now apply blur and bkg subtraction to each channel
			if (blurImage) run("Gaussian Blur...", "sigma=0.80");
			if (substractBackground) {
				if (endsWith(wellChannelFileList[currentFile], "C01.tif")) run("Subtract Background...", "rolling=" + bkgValueSubstractionArray[currentChannel] +  " light");  //brightfield
				if (endsWith(wellChannelFileList[currentFile], "C02.tif")) run("Subtract Background...", "rolling=" + bkgValueSubstractionArray[currentChannel] +  " stack");
				if (endsWith(wellChannelFileList[currentFile], "C03.tif")) run("Subtract Background...", "rolling=" + bkgValueSubstractionArray[currentChannel] +  " stack");		
				}
			//run("Measure"); getStatistics(area, mean, min, max, std, histogram); print(area, mean, min, max, std);
			//setMinAndMax(contrastValueArray[currentChannel * 2], contrastValueArray[currentChannel * 2 + 1]);
			if (currentFile == 0) {
				firstImage = currentImage;
				fileName = File.nameWithoutExtension;   //getTitle(); for saving later, name of stack
				if (currentChannel == 0) {
					wellFileName = substring(fileName,0,lengthOf(fileName)-3);
					print("well:", wellFileName);
					}
				} else {  // join current image to stack
				if (nImages > 1) run("Concatenate...", "  title=[" + firstImage + "] image1=" + firstImage + " image2=" + currentImage + " image3=[-- None --]");
				}
			} //end for all images per channel
		// all wellFields are open for one channel, now merge and save to RGB or merge stack
		for (currentRGBChannel = 0; currentRGBChannel < channelList.length; currentRGBChannel++) {  
			if (endsWith(firstImage, fileEndArray[currentRGBChannel])) mergeChannelString = mergeChannelString + " c" + channelToRGBArray[currentRGBChannel] + "=" + getTitle(); //generate merge string by checking each file end
			}	
		if (reverseOrder) run("Reverse");
		//set contrast
		setMinAndMax(contrastValueArray[currentChannel * 2], contrastValueArray[currentChannel * 2 + 1]);
		} //end for all channels in well
	//save image(stack or single image) to temp folder
	if (RGBstitch) {
		print(mergeChannelString);
		run("Merge Channels...", mergeChannelString + " create");
		}
//waitForUser("ok?");		
	rgbStack = getTitle();
	if (!skipWell) {
		for (currentField = 1; currentField <= fieldList.length; currentField++) {
			selectWindow(rgbStack);
			if (RGBstitch) {
				run("Duplicate...", "duplicate slices=" + currentField);
				run("RGB Color");
				} else {
				run("Duplicate...", "duplicate range=" + currentField + "-" + currentField);	
				}
			saveAs("Tiff", tempPath + fileName + fileTag + "_f" + getNumberToString(currentField, 0, 2) + ".tif");
			//if (RGBstitch) close(); //saved RGB tif
			//close(); //composite
			while (nImages > 1) close();
			print("saved temporarily as " + tempPath + fileName + fileTag + "_f" + getNumberToString(currentField, 0, 2) + ".tif");  //to log window
			saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
			}
		selectWindow(rgbStack);
		close(); //RGB-composite stack	

		//now run the stiching plugin 
		// for detail see this weib site: http://fiji.sc/Image_Stitching#Timelapse_alignment_for_Grid.2FCollection_Stitching	
		run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Down                ] grid_size_x=" + stitchGridX	+ " grid_size_y=" + stitchGridY	+ " tile_overlap_x=" + stitchOverlapX + " tile_overlap_y=" + stitchOverlapY + "  first_file_index_i=1 directory=" + tempPath + " file_names=" + fileName + fileTag + "_f" + "{ii}.tif" + " output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=" + stitchRegThres + " max/avg_displacement_threshold=" + stitchMaxDispThres + " absolute_displacement_threshold=" + stitchAbsDispThres + " compute_overlap display_fusion subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");  //image_output=[Fuse and display] or image_output=[Write to disk] output_directory=" + outputPath
		//run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Down                ] grid_size_x=2 grid_size_y=3 tile_overlap=30 first_file_index_i=1 directory=C:\\Users\\stoeter\\AppData\\Local\\Temp\\Fiji_Temp_Folder_Stitching\\ file_names=AssayPlate_Matrical_9MLG_lowGlass_B03_T0001F0{ii}L01A03Z01C01.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Write to disk] output_directory=C:\\Users\\stoeter\\AppData\\Local\\Temp\\Fiji_Temp_Folder_Stitching\\");
		outputImageName = getTitle();
		//waitForUser("done");
		if (!RGBstitch) for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) { 
			setMinAndMax(contrastValueArray[currentChannel * 2], contrastValueArray[currentChannel * 2 + 1]);
			}
		if (invertBFforPNG) {
			setSlice(BFchannel);
			run("Invert LUT"); //invert Bright filed image (C01.tif)
			saveAs("Jpeg", outputPath + "Stitched" + wellFileName + fileTag + ".jpg");
			setSlice(BFchannel);
			run("Invert LUT"); //invert back
			} else {
			saveAs("Jpeg", outputPath + "Stitched" + wellFileName + fileTag + ".jpg");
			}
		if (RGBstitch) {
			outputImageName = "Stitched" + wellFileName + fileTag + ".jpg";  // saveAs("Jpeg",...) doesnt change file name after saving if image is composite! .. if it is RGB then it does +> getTitle();
			} else {
			outputImageName = getTitle();
			}
		print("saved stiched image for " + wellList[currentWell], "as", outputImageName);  //to log window
		if (saveAsGreyStack && nSlices > 1) Stack.setDisplayMode("grayscale");
		if (invertBFforTIF) {
			setSlice(BFchannel);
			run("Invert LUT"); //invert Bright filed image (C01.tif)
			saveAs("Tiff", outputPath + "Stitched" + wellFileName + fileTag + ".tif");
			} else {
			saveAs("Tiff", outputPath + "Stitched" + wellFileName + fileTag + ".tif");
			}
		outputImageName = getTitle();
		print("saved stiched image for " + wellList[currentWell], "as", outputImageName);  //to log window
		close();
	
		//waitForUser("done end");
		// clean up temp folder
		filesInTempFolder = getFileList(tempPath);
		for(file = 0; file < filesInTempFolder.length; file++) {
			print("deleting:", filesInTempFolder[file], File.delete(tempPath + filesInTempFolder[file]));
			}
		print("deleted", filesInTempFolder.length, "files from temp folder:", tempPath);
		} else {
		print("Well skipped due to incorrect image numbers: current wellFields = " + wellChannelFileList.length + ", all fields = " + fieldList.length + ", all channels = " + channelList.length);
		run("Close All");
		}
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
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
for (i=0; i < fileListFunction.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileListFunction[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPathFunction + fileListFunction[i], displayList);
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

//function filters a list for a certain string (filter)
//example: myList = getFilteredList(myList, "myText", true);
function getFilteredList(inputList, filterStringFunction, displayList {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " files found after filtering: " + filterStringFunction); 
if (displayList) {Array.show("List after filtering for " + filterStringFunction, returnedFileList);}
return returnedList;
}

//function returnes the unique wells of an array of CV7000 files
//example: myUniqueWells = getUniqueWellListCV7000(myList, true);
function getUniqueWellListCV7000(inputArray, displayList) {
currentWell = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00"));   //first well found
returnedWellList = newArray(currentWell);     //this list stores all unique wells found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned well list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedWellList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentWell = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00"));
		if(returnedWellList[j] == currentWell) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedWellList = Array.concat(returnedWellList, currentWell);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellList.length + " wells found."); 
Array.sort(returnedWellList);
if (displayList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}

//function returnes the unique well files (all fields of all wells, e.g. G10_T0001F001) of an array of CV7000 files
//example: myUniqueWellFileds = getUniqueWellFieldListCV7000(myList, true);
function getUniqueWellFieldListCV7000(inputArray, displayList) {
currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00")+10);   //first well field found
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
//print("start:", currentWellField, returnedWellFieldList.length);
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00")+10);
		//print(i,j,currentWellField, returnedWellFieldList[j]);
		if(returnedWellFieldList[j] == currentWellField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	//print("final:", currentWellField, valueUnique, returnedWellFieldList.length);
	if (valueUnique) returnedWellFieldList = Array.concat(returnedWellFieldList, currentWellField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellFieldList.length + " wells fields found."); 
Array.sort(returnedWellFieldList);
if (displayList) {Array.show("List of " + returnedWellFieldList.length + " unique well fields", returnedWellFieldList);}	
return returnedWellFieldList;
}

//function returnes the unique fields (all fields of all wells, e.g. F001, F002,...) of an array of CV7000 files
//example: myUniqueFields = getUniqueFieldListCV7000(myList, true);
function getUniqueFieldListCV7000(inputArray, displayList) {
currentField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+6,lastIndexOf(inputArray[0],"_T00")+10);   //first field found
returnedFieldList = newArray(currentField);     //this list stores all unique fields found and is returned at the end of the function
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentField = substring(inputArray[i], lastIndexOf(inputArray[i],"_T00")+6, lastIndexOf(inputArray[i],"_T00")+10);
		if(returnedFieldList[j] == currentField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedFieldList = Array.concat(returnedFieldList, currentField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedFieldList.length + " fields found."); 
Array.sort(returnedFieldList);
if (displayList) {Array.show("List of " + returnedFieldList.length + " unique fields", returnedFieldList);}	
return returnedFieldList;
}

//function returnes the unique channels (e.g. C01) of an array of CV7000 files
//example: myUniqueChannels = getUniqueChannelListCV7000(myList, true);
function getUniqueChannelListCV7000(inputArray, displayList) {
currentChannel = substring(inputArray[0],lastIndexOf(inputArray[0],".tif")-3,lastIndexOf(inputArray[0],".tif"));   //first channel found
returnedChannelList = newArray(currentChannel);     //this list stores all unique channels found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned channel list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedChannelList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentChannel = substring(inputArray[i],lastIndexOf(inputArray[i],".tif")-3,lastIndexOf(inputArray[i],".tif"));
		if(returnedChannelList[j] == currentChannel) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedChannelList = Array.concat(returnedChannelList, currentChannel);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedChannelList.length + " channels found."); 
Array.sort(returnedChannelList);
if (displayList) {Array.show("List of " + returnedChannelList.length + " unique channels", returnedChannelList);}	
return returnedChannelList;
}

//function saves the log window in the given path
//example: saveLog("C:\\Temp\\Log_temp.txt");
function saveLog(logPath) {
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
saveAs("Text", logPath);
if (nImages > 0) selectWindow(currentWindow);
}

//function returns a number in specific string format, e.g 2.5 => 02.500
//example: myStringNumber = getNumberToString(2.5, 3, 6);
function getNumberToString(number, decimalPlaces, lengthNumberString) {
numberString = "000000000000" + toString(number, decimalPlaces);  //convert to number to string and add zeros in the front
numberString = substring(numberString, lengthOf(numberString) - lengthNumberString, lengthOf(numberString)); //shorten string to lengthNumberString
return numberString;
}
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////












