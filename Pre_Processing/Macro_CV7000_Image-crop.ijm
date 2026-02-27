//CV7000-Z-Projection
macroName = "CV7000-Image-crop";
macroShortDescription = "This macro opens CV7000 images of a well-field-channel and does cropping based on a defined ROI.";
macroDescription = "This macro reads single CV7000 images of a well as .tif ." +
	"\nThe chosen folder will be searched for images including subfolders." +
	"\nOption to select several input folders for batch processing at end of GUI." +
	"\nAll images of a unique well, field and channel are opened and cropped for a given ROI." +
	"\nROI dimension and position can be adjusted. Pixel size can be automatically corrected." +
	"\nCropped images can automatically overwrite and replace the input (raw) data, be saved in a separate folder 'Cropped', or saved with file tag (to be specified)." +
	"\nOption to copy CV7000 meta data files to output folder.";
macroRelease = "2.0.0_260226";
macroAuthor = "by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;

//===== Script Parameters =====
#@ String  spMacroTitle      (label="<html><font color=#EE1111><em><b>===== Macro CV7000 Image crop =====</b></em></font></html>", visibility=MESSAGE, required=false, description="This macro opens CV7000 images of a well-field-channel and does crops a defined ROI.\nFiji-Tools-for-HCS by TDS@MPI-CBG, Version 2.0.4_260203") 
#@ String  spMacroSubTitle   (label="<html><font color=#EE1111><em>----- use mouse-roll-over for help ----- </em></font></html>", visibility=MESSAGE, required=false, description="<html>Essential configuration in <font color=#FF6600>orange</font>. Non-persistent default values in <html><font color=#000077>dark blue</font>.<br>For further help and hints see also in Log window...</html>") 
// image input and output
#@ String  spInput           (label="<html><b>Select one or multiple CV7000 folders:</b></html>", visibility=MESSAGE, required=false, description="Select CV7000 measurement folder, subfolders are included.\nOutput folder does not need to be specified") 
#@ File[]  inputPaths        (label="<html><font color=#FF6600>Input folders:</font></html>", style="both", description="For multiple folders hold SHIFT / STRG ...") 
#@ File    outputPath        (label="<html><font color=#000077>Specific output folder?</font></html>", style="directory", required=false, persist=false, description="Not essential. Per default projections will be saved in subfolder 'Cropped' of selected input folder.\nChange default output folder name selection 'Crop tag' as 'customize own tag'") 
//set crop secific settings
#@ String  spCrop            (label="<html><b>Cropping - Define settings ...</b></html>", visibility=MESSAGE, required=false, description="Customize ROI cropping settings ...") 
#@ Integer cropWidth         (label="<html><font color=#FF6600>Crop ROI width (x-dim.):", min=0, max=10000, value=1200, description="Specify width of crop ROI = dimension in x") 
#@ Integer cropHeight        (label="<html><font color=#FF6600>Crop ROI height (y-dim.):", min=0, max=10000, value=1200, description="Specify height of crop ROI = dimension in y") 
#@ Integer cropXpos          (label="<html><font color=#FF6600>Crop ROI x-position (x-pos.):", min=0, max=10000, value=680, description="Specify position of crop ROI = x-coordinate of top left corner of crop ROI")
#@ Integer cropYpos          (label="<html><font color=#FF6600>Crop ROI y-position (y-pos.):", min=0, max=10000, value=480, description="Specify position of crop ROI = y-coordinate of top left corner of crop ROI")
#@ String  cropFileTag       (label="Crop tag:", choices={"*NONE*", "_cropped", "_small", "customize own tag"}, style="listBox", description="Customize file tag for cropped image, e.g. *NONE* = as input file, ..._cropped.tif, or _200x200..., or ... customize default output folder name (customize own tag)") 
#@ Boolean overwriteImage    (label="<html><font color=#000077>Overwrite input image in same folder?</font></html>", value=false, persist=false, description="If checked the input files and raw data will be overwritten in same folder. When unchecked (default) cropped images are saved in a subfolder (Cropped).") 
// image file filter
#@ String  spImageFileFilter (label="<html><b>Image file filter - Define the files to be processed ...</b></html>", visibility=MESSAGE, required=false, description="This feature helps to shape and filter the file list to obtain a specific set of image files") 
#@ String  fileExtension     (label="<html><font color=#000077>Files should have this extension:</font></html>", value=".tif", persist=false, description="Enter an image extension (like '.tif') to e.g. exclude file types other than CV7000 meta data files") 
#@ String  spDefineFilter    (label="<html>Define filter for files:</html>", visibility=MESSAGE, required=false, description="Below three consecutive filters can be configured to include or exclude files based on a specific text tags")
#@ String  filterStrings0    (label="1) Filter this text from file list:", value="", description="Enter text to specify file names (1), e.g for channel: C01.tif")
#@ String  filterTerms0      (label="<html><font color=#000077>1) Files with text are included/excluded?</font></html>", choices={"no filtering", "include", "exclude"}, persist=false, style="radioButtonHorizontal", description="Choose to include or exclude files with specific text (1)") 
#@ String  filterStrings1    (label="2) Filter this text from file list:", value="", description="Enter text to specify file names (2), e.g. for well: _C05_") 
#@ String  filterTerms1      (label="<html><font color=#000077>2) Files with text are included/excluded?</font></html>", choices={"no filtering", "include", "exclude"}, persist=false, style="radioButtonHorizontal", description="Choose to include or exclude files with specific text (2)") 
#@ String  filterStrings2    (label="3) Filter this text from file list:", value="", description="Enter text to specify file names (3), ...") 
#@ String  filterTerms2      (label="<html><font color=#000077>3) Files with text are included/excluded?</font></html>", choices={"no filtering", "include", "exclude"}, persist=false, style="radioButtonHorizontal", description="Choose to include or exclude files with specific text (3)") 
#@ Boolean displayFileList   (label="<html><font color=#000077>Display the file lists?</font></html>", value=false, persist=false, description="If checked the file lists are displyed at each step of the Image file filter")                      //if check file lists will be displayed
#@ Boolean displayMetaData   (label="<html><font color=#000077>Display unique values of meta data?</font></html>", value=false, persist=false, description="If checked unique values of meta data from file names (like wells, fields, channel, etc.) are displyed in separate windows")    //if check file lists will be displayed
//set general settings
#@ String  spGeneral         (label="<html><b>General settings ...</b></html>", visibility=MESSAGE, required=false, description="Select other general features of the script") 
#@ Boolean doPixelSizeCorr   (label="<html><font color=#000077>Automatically correct pixel size?</font></html>", value=true, persist=false, description="If checked .mrf file will be read and the pixel size will be corrected") 
#@ Boolean copyMetaDataFiles (label="<html><font color=#000077>Copy CV7000 meta data files?</font></html>", value=false, persist=false, description="If checked meta data files from CV7000, such as .mrf, .mes, correction files, etc., will be copied to the output path") 
#@ Boolean batchMode         (label="<html><font color=#000077>Set batch mode (hide images)?</font></html>", value=true, persist=false, description="If checked no images will be displayed while processing") 

//print macro name and current time to Log window
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("\\Clear");
print(macroName, "(" + macroRelease + ")", "\nStart:",year + "-" + month + "-" + dayOfMonth + ", h" + hour + "-m" + minute + "-s" + second);
print(macroDescription);
print(macroHelpURL);
print(generalHelpURL);

// ===== organize oupput folder stttings  =====
print("\n=== Input / Output settings ===\nInput path(s):");
for (i = 0; i < inputPaths.length; i++) {
	inputPaths[i] = inputPaths[i] + File.separator;
	print(inputPaths[i]);
}
//Array.show(inputPaths);
print("In total", inputPaths.length, "folder(s) will be processed...");

// ===== organize output (folder) settings  =====
defaultOutputfolderName = "Cropped";
// if no selection in script parameters, then it is output path is ImageJ path!?? Set variavle outputPathSelected then to 0, it is 1 when an outputPath was selected
//print((replace(outputPath + File.separator, File.separator, "/") == replace(getDir("imagej") , File.separator, "/")));
//outputPathSelected = !( replace(outputPath + File.separator, File.separator, "/") == replace(getDir("imagej") , File.separator, "/") );  // cannot compare strings with backslash!???
//if (outputPath == 0) outputPathSelected = false;  // if nothing is selected in GUI then the return value will be 0, not NA or null (see here: https://forum.image.sc/t/issue-with-script-parameter-file-in-fiji-when-not-selected-and-the-getdir-imagej-function/91420)
//print(outputPathSelected);

//set output crop folder name
if (cropFileTag == "customize own tag") { // user defined output folder name
	Dialog.create("Set specific crop file tag options (*NONE*=as input file)");
	Dialog.addString("Crop file tag:", "_cropped");
	Dialog.addString("Change default output folder name?", defaultOutputfolderName);
	Dialog.show();
	cropFileTag = Dialog.getString();
	defaultOutputfolderName = Dialog.getString();
	print("Default output folder was set to:", defaultOutputfolderName);
	} 
if (cropFileTag == "*NONE*") cropFileTag = "";

if ( (inputPaths.length > 1) || outputPath == 0 ) {     // if nothing is selected in GUI then the return value of outpuPath will be 0 (see above)
	print("Selected output path will be ignored and output folders will be generated automatically in each input folder");
	outputPathSelected = false;
	} else {
	outputPath = outputPath + File.separator;
	print("Output path:", outputPath, "");
	outputPathSelected = true;
	}

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt save copy_column copy_row save_column save_row");	 // set byte order to little-Endian / Intel -> 'save'

run("Close All");
//run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 

//set variables
var CV7000metadataFileList = newArray(0);                                     //initialize - list of files (metadata forom CV7000) that will be copied to outoutPath
doubleCheckOverwriting = 1;

//set array variables
var defaultFilterStrings = newArray("DC_sCMOS #","SC_BP","");
print("\nFiles (images) containing these strings will be automatically filtered out:");
Array.print(defaultFilterStrings);                                               //pre-definition of extension
var filterStrings = newArray(filterStrings0, filterStrings1, filterStrings2);     // get variable settings from script parameter GUI
var availableFilterTerms = newArray("no filtering", "include", "exclude");    //dont change this
var filterTerms = newArray(filterTerms0, filterTerms1, filterTerms2);         // get variable settings from script parameter GUI

//setDialogImageFileFilter();  //replaced by scrip parameters
filterStringsUserGUI = filterStrings;                                        //store strings that user enterd in "backup variable" 
filterTermsUserGUI = filterTerms;                                            //store terms that user enterd in "backup variable" 

print("Image file filter:", filterTerms[0],filterStrings[0] + ";",filterTerms[1],filterStrings[1] + ";",filterTerms[2],filterStrings[2]);

// start looping over all folders
for (currentFolder = 0; currentFolder < inputPaths.length; currentFolder++) { // folder by folder
    inputPath = inputPaths[currentFolder];   // need to create static variable here from current array value, because a funtion (getFileListSubfolder) need to check against this global variable
	print("\n================== starting processing folder #" + (currentFolder + 1) + "... ====================");
    print("Preparation for folder #" + (currentFolder + 1) + ":", inputPaths[currentFolder]);  //to log window

// if multiple folders are selected or no outputPath was selected (see above) then make default output folder in input folder
    if (!outputPathSelected) {  
        if (overwriteImage) {
        	print("Output folder = input folder -> possible overwriting of files (!) ... ");  //to log window
        	outputPath = 0;      // outputPath not know at this stage (only later when tif is opened), therefore set it o 0, if nothing is selected in GUI then the return value of outpuPath will be 0 (see above)
        	} else {
	        //outputPath = substring(inputPaths[currentFolder], 0, lastIndexOf(inputPaths[currentFolder], File.separator)) + File.separator + "Zprojection" + File.separator;
	        outputPath = inputPath + defaultOutputfolderName + File.separator;
	        File.makeDirectory(outputPath);
	        print("New output folder -> made folder for cropped files: " + outputPath);  //to log window
	        }
    	}
        
	//set log file number
	tempLogFileNumber = 1;
	if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");	
	
	print("Processing file list...");

	// for multiple folders from second iteration on the several lists need to be updated/reseted for next iteration, like fileList, CV7000metadataFileList, well/field/channelList, filterStrings/Terms(user/GUI variables)
    if (currentFolder > 0)  {                         // dont do on first iteration: from second iteration on, get file list from new folder
    	CV7000metadataFileList = newArray(0);         // reset the meta data file list
    	filterStrings = filterStringsUserGUI;         //restore user enterd strings from "backup variable" 
    	filterTerms = filterTermsUserGUI;
    	displayFileList = false;                      // dont display lists after the first iteration
		displayMetaData = false;
    	}
    //get file list ALL
    fileList = getFileListSubfolder(inputPaths[currentFolder], displayFileList);  //read all files in subfolders                          
    fileList = getFileTypeAndCV7000metaDataFiles(fileList, fileExtension, displayFileList);   // new funtion to store the CV7000 meta data files in separate list (CV7000metadataFileList)
    filterStrings = filterStringsUserGUI;                              //restore user enterd strings from "backup variable" 
    filterTerms = filterTermsUserGUI;                                  //restore user enterd terms from "backup variable"
    fileList = getFilteredFileList(fileList, false, displayFileList);    //filter for strings
    if (fileList.length == 0) {
    	print("No files to process, folder is skipped...");
    	//print current time to Log window and save log
    	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
    	if ((currentFolder + 1 ) < inputPaths.length) {
        	print("Macro executed successfully for this folder.\nFinished folder:", inputPaths[currentFolder],"at", year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
        	} else {
        	print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
        	}
    	saveLogFinal(logPath, tempLogFileNumber);
    	continue;
    	}
    //print("removing correction files from file list containing text", defaultFilterStrings[0], defaultFilterStrings[1], defaultFilterStrings[2]);
    wellList = getUniqueWellListCV7000(fileList, displayMetaData);
    wellFieldList = getUniqueWellFieldListCV7000(fileList, displayMetaData);
    fieldList = getUniqueFieldListCV7000(fileList, displayMetaData);
    zPlaneList = getUniqueZplaneListCV7000(fileList, displayMetaData);
    channelList = getUniqueChannelListCV7000(fileList, displayMetaData);
    //print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n");
    
    if (currentFolder == 0) { // in first iteration check stack size and options
    	//print("fileList.length, wellFieldList.length, channelList.length", fileList.length, wellFieldList.length, channelList.length);
		if (displayFileList || displayMetaData) waitForUser("Take a look at the list windows...");  //give user time to analyse the lists 
    	}

    print("Overwriting input images (0=false, 1=true):", overwriteImage, "copy CV700 meta data files:", copyMetaDataFiles, "using file tag:", cropFileTag);
	//print(outputPath);
	//saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt"); 

    if (doPixelSizeCorr) pixelSizeMrf = readMRFfile(inputPaths[currentFolder]);  // get pixel size from .mrf file

    print("\n===== starting processing files... =====");
    setBatchMode(batchMode);
	print("Input path is:", inputPaths[currentFolder]);
    if (copyMetaDataFiles) copyFiles(CV7000metadataFileList, outputPath);

    //go through all files
    for (currentWellField = 0; currentWellField < wellFieldList.length; currentWellField++) {   // well by well
    print("well-field (" + (currentWellField + 1) + "/" + wellFieldList.length + ") ...");  //to log window
        for (currentChannel = 0; currentChannel < channelList.length; currentChannel++) {  // channel by channel per well
            //define new filters and filter file list for currentWell and currentChannel
            filterStrings = newArray(wellFieldList[currentWellField],channelList[currentChannel] + ".tif","");      //pre-definition of strings to filter, add "_" because well strings e.g. A03, L01, C02 can be in file name at other places, e.g ..._A06_T0001F001L01A03Z01C02.tif and ".tif" to excluse well C02 instead of channel C02
            filterTerms = newArray("include", "include", "no filtering");  //pre-definition of filter types 
            wellChannelFileList = getFilteredFileList(fileList, false, false);
            if (currentWellField == 0) updateMRFfile(inputPath, cropWidth, cropHeight, channelList[currentChannel]);
            
            //now open all files (wellChannelFileList) that belong to one wellField in one channel
            for (currentFile = 0; currentFile < wellChannelFileList.length; currentFile++) {
                //image sequence & regEx would be possible, but it seems to be slow: run("Image Sequence...", "open=Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\ file=(_B03_.*C01) sort");
                IJ.redirectErrorMessages();
                if (File.exists(wellChannelFileList[currentFile])) {
                    open(wellChannelFileList[currentFile]);
                    currentImage = getTitle();                    
                    print("opened (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
                    if (!outputPathSelected & overwriteImage) {
                    	//print(File.directory);
                    	outputPath = File.directory;
                    	}
                    outputFileName = substring(currentImage, 0, lengthOf(currentImage) - 4) + cropFileTag + ".tif";   // if cropFileTag == "*NONE*" => cropFileTag = "" means like input file name
                    if (doPixelSizeCorr) correctPixelSize(pixelSizeMrf);   // do pixel size / unit correction		
					run("Specify...", "width=" + cropWidth + " height=" + cropHeight + " x=" + cropXpos+ " y=" + cropYpos);
					run("Crop");
					if (doubleCheckOverwriting) {     // default and intiallysed as 1 = true; safety rule, before overwriting for the first time, as the user for confirmation on all subsequent files and folders 
						if (File.exists(outputPath + outputFileName)) {
							print("\n === WARNING!!! ===\n This file exists:\n", outputPath + outputFileName);
							print("If you ckeck the box and continue, then ALL the files with the same name will be OVERWRITTEN from here on !!!");
							Dialog.create("=== WARNING! ===");
							Dialog.addMessage("            === WARNING! ===\nDo you really want to overwrite files?", 18, "#ff0000");
							Dialog.addMessage("Please check also log file....");
							Dialog.addCheckbox("Confirm overwriting files (tick for 'yes')?", false);
							Dialog.show();
							doubleCheckOverwriting = !(Dialog.getCheckbox());  // is !true => false if overwriting is confirmed
							print("Overwriting confirmation was set to:", !doubleCheckOverwriting);  //here if checked !!true => true
							if (doubleCheckOverwriting) {
								print("EXIT: overwriting was not confirmed!\n Please select not to overwrite in the GUI upon scipt launch or select other than *NONE* file tag.");
								saveLogFinal(outputPath, tempLogFileNumber);
								exit("EXIT: overwriting was not confirmed!\nPlease see log...");
								}
							} // file exists
						} // double checking overwriting
					saveAs("Tiff", outputPath + outputFileName);
					print("saved cropped image as " + outputPath + outputFileName);  //to log window			
					close();              
                    } else {
                    print("file not found (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
                    } //end for all images per wellField	
                showProgress(currentFile / wellChannelFileList.length);
                showStatus("processing" + fileList[currentFile]);                
                } //end for all images per channel	
            //waitForUser("done");	
            run("Close All");	
            } //end for all channels in well
        // clear memory
        print("current memory:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");
        run("Collect Garbage");
        print("memory after clearing:", parseInt(IJ.currentMemory())/(1024*1024*1024), "GB");
        saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");
        }  //end for all wells
                
    //print current time to Log window and save log
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
    if ((currentFolder + 1 ) < inputPaths.length) {
        print("Macro executed successfully for this folder.\nFinished folder:", inputPaths[currentFolder],"at", year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
        } else {
        print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second);
        }
        
    // set byte order again to standard
	run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	    
    saveLogFinal(outputPath, tempLogFileNumber);
	} // unitl here processing of multiple folders

/////////////////////////////////////////////////////////////////////////////////////////////
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////


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
		print(returnedFileList.length + " file(s) found after filter: " + filterTerms[i] + " text " + filterStrings[i] + "."); 
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
	//print(i, inputPathFunction + fileListFunction[i]);
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	//print("fixed", i, inputPathFunction + fileListFunction[i]);
	if (endsWith(fileListFunction[i], File.separator)) {   //if it is a folder
		returnedFileListTemp = newArray(0);
		returnedFileListTemp = getFileListSubfolder(inputPathFunction + fileListFunction[i], displayList);
		returnedFileList = Array.concat(returnedFileList, returnedFileListTemp);
		} else {  									//if it is a file
		returnedFileList = Array.concat(returnedFileList, inputPathFunction + fileListFunction[i]);
		//print(i, inputPathFunction + fileListFunction[i]); //to log window
		}
	}
if(inputPathFunction == inputPath) { //if local variable is equal to global path variable = if path is folder and NOT subfolder
	print(returnedFileList.length + " file(s) found in selected folder and subfolders."); 	
	if (displayList) {Array.show("All files - all",returnedFileList);} 	
	}
return returnedFileList;
}

//function filters all files with certain extension
//example: myFileList = getFileTypeAndCV7000metaDataFiles(myFileList, ".tif", true);
function getFileTypeAndCV7000metaDataFiles(fileListFunction, fileExtension, displayList) {
returnedFileList = newArray(0);     //this list stores all files found to have the extension and is returned at the end of the function
defaultCV7000metadataFileExtensionList = newArray(".icr", ".mes", ".mlf", ".mrf", ".wpi", ".wpp", ".xml");
if (lengthOf(fileExtension) > 0) {
	for (i = 0; i < fileListFunction.length; i++) {
		if (endsWith(fileListFunction[i], fileExtension)) {                    // if this is e.g. .tif
			if (indexOf(fileListFunction[i], defaultFilterStrings[0]) > 0 ||   // is "DC_sCMOS #"
				indexOf(fileListFunction[i], defaultFilterStrings[1]) > 0) {   // is "SC_BP"
				CV7000metadataFileList = Array.concat(CV7000metadataFileList, fileListFunction[i]);	
				print("Added " + fileListFunction[i] + " to CV7000 meta data file list");
				} else {
				returnedFileList = Array.concat(returnedFileList, fileListFunction[i]);
				}
			} else {                                                             // if this file has other file extension
				if (endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[0]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[1]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[2]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[3]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[4]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[5]) ||
					endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[6]) 
					//endsWith(fileListFunction[i], defaultCV7000metadataFileExtensionList[7]) //  see definition of array defaultCV7000metadataFileExtensionList in the beginning
					) {
					CV7000metadataFileList = Array.concat(CV7000metadataFileList, fileListFunction[i]);
					print("Added " + fileListFunction[i] + " to CV7000 meta data file list");
				}
			}
		}
		print(returnedFileList.length + " file(s) found with extension " + fileExtension + ".");
		print(CV7000metadataFileList.length + " file(s) of CV7000 meta data found");
		if (displayList) {Array.show("All files - filtered for " + fileExtension, returnedFileList);Array.show("CV7000 meta data files", CV7000metadataFileList);} 
		} else {
		returnedFileList = fileListFunction;	
		}
return returnedFileList;   // note: metadataFileList is globel variable (var) and does not need to be returned
}

//function filters a list for a certain string (filter)
//example: myList = getFilteredList(myList, "myText", true);
function getFilteredList(inputList, filterStringFunction, displayList {
skippedFilter = 0;	
returnedList = newArray(0); //this list stores all items of the input list that were found to contain the filter string and is returned at the end of the function
for (i = 0; i < inputList.length; i++) {
	if (indexOf(inputList[i],filterStringFunction) != -1) returnedList = Array.concat(returnedList,inputList[i]);
	}
print(returnedList.length + " file(s) found after filtering: " + filterStringFunction); 
if (displayList) {Array.show("List after filtering for " + filterStringFunction, returnedFileList);}
return returnedList;
}

//function returnes the unique wells of an array of CV7000 files
//example: myUniqueWells = getUniqueWellListCV7000(myList, true);
function getUniqueWellListCV7000(inputArray, displayList) {
if (lastIndexOf(inputArray[0],"_T0") > 0) { //check first well
	currentWell = substring(inputArray[0],lastIndexOf(inputArray[0],"_T0")-3,lastIndexOf(inputArray[0],"_T0"));   //first well found
	} else {
	print("no well found in path:", inputArray[i]);	
	exit("No well information found in file name. Please double-check the file filtering...");
	}	
returnedWellList = newArray(currentWell);     //this list stores all unique wells found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned well list
	valueUnique = true;						//as long as value was not found in array of unique values
	if (lastIndexOf(inputArray[i],"_T0") > 0) {  // if CV7000 file names are recognized
		while (valueUnique && (returnedWellList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
			currentWell = substring(inputArray[i],lastIndexOf(inputArray[i],"_T0")-3,lastIndexOf(inputArray[i],"_T0"));
			if (returnedWellList[j] == currentWell) {
				valueUnique = false;			//if value was found in array of unique values stop while loop
				} else {
				j++;
				}
			}  //end while
		} else {
		print("no well found in path:", inputArray[i]);	
		}		
	if (valueUnique) returnedWellList = Array.concat(returnedWellList, currentWell);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellList.length + " well(s) found."); 
Array.sort(returnedWellList);
Array.print(returnedWellList);
if (displayList) {Array.show("List of " + returnedWellList.length + " unique wells", returnedWellList);}	
return returnedWellList;
}

//function returnes the unique well files (all fields of all wells, e.g. G10_T0001F001) of an array of CV7000 files
//example: myUniqueWellFileds = getUniqueWellFieldListCV7000(myList, true);
function getUniqueWellFieldListCV7000(inputArray, displayList) {
if (lastIndexOf(inputArray[0],"_T0") > 0) { //check first well field
	currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T0")-3,lastIndexOf(inputArray[0],"_T0")+10);   //first well field found
	} else {
	print("no well found in path:", inputArray[i]);	
	exit("No well field information found in file name. Please double-check the file filtering...");
	}
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
//print("start:", currentWellField, returnedWellFieldList.length);
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	if (lastIndexOf(inputArray[i],"_T0") > 0) {  // if CV7000 file names are recognized
		while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
			currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T0")-3,lastIndexOf(inputArray[i],"_T0")+10);
			//print(i,j,currentWellField, returnedWellFieldList[j]);
			if(returnedWellFieldList[j] == currentWellField) {
				valueUnique = false;			//if value was found in array of unique values stop while loop
				} else {
				j++;
				}
			}  //end while
		} else {
		print("no well field found in path:", inputArray[i]);	
		}		
	//print("final:", currentWellField, valueUnique, returnedWellFieldList.length);
	if (valueUnique) returnedWellFieldList = Array.concat(returnedWellFieldList, currentWellField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellFieldList.length + " well field(s) found."); 
Array.sort(returnedWellFieldList);
Array.print(returnedWellFieldList);
if (displayList) {Array.show("List of " + returnedWellFieldList.length + " unique well fields", returnedWellFieldList);}	
return returnedWellFieldList;
}


//function returnes the unique fields (all fields of all wells, e.g. F001, F002,...) of an array of CV7000 files
//example: myUniqueFields = getUniqueFieldListCV7000(myList, true);
function getUniqueFieldListCV7000(inputArray, displayList) {
currentField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T0")+6,lastIndexOf(inputArray[0],"_T0")+10);   //first field found
returnedFieldList = newArray(currentField);     //this list stores all unique fields found and is returned at the end of the function
for (i = 0; i < inputArray.length; i++) {
	j = 0;									//counter for returned field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentField = substring(inputArray[i], lastIndexOf(inputArray[i],"_T0")+6, lastIndexOf(inputArray[i],"_T0")+10);
		if(returnedFieldList[j] == currentField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedFieldList = Array.concat(returnedFieldList, currentField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedFieldList.length + " field(s) found."); 
Array.sort(returnedFieldList);
Array.print(returnedFieldList);
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
print(returnedChannelList.length + " channel(s) found."); 
Array.sort(returnedChannelList);
Array.print(returnedChannelList);
if (displayList) {Array.show("List of " + returnedChannelList.length + " unique channels", returnedChannelList);}	
return returnedChannelList;
}

//function returnes the unique z-planes (e.g. Z01) of an array of CV7000 files
//example: myUniqueZplanes = getUniqueZplaneListCV7000(myList, true);
function getUniqueZplaneListCV7000(inputArray, displayList) {
currentZplane = substring(inputArray[0],lastIndexOf(inputArray[0],".tif")-6,lastIndexOf(inputArray[0],".tif")-3);   //first Zplane found
returnedZplaneList = newArray(currentZplane);     //this list stores all unique Zplanes found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned Zplane list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedZplaneList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentZplane = substring(inputArray[i],lastIndexOf(inputArray[i],".tif")-6,lastIndexOf(inputArray[i],".tif")-3);
		if(returnedZplaneList[j] == currentZplane) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedZplaneList = Array.concat(returnedZplaneList, currentZplane);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedZplaneList.length + " Zplane(s) found."); 
Array.sort(returnedZplaneList);
Array.print(returnedZplaneList);
if (displayList) {Array.show("List of " + returnedZplaneList.length + " unique Zplanes", returnedZplaneList);}	
return returnedZplaneList;
}


//function saves the log window in the given path
//example: saveLog("C:\\Temp\\Log_temp.txt");
function saveLog(logPath) {
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
saveAs("Text", logPath);
if (nImages > 0) selectWindow(currentWindow);
}


//function saves the log window in the given folder and deleted tempLofFile
//example: saveLogFinal("C:\\Temp\\");
function saveLogFinal(logPath, tempLogFileNumber) {
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
if (nImages > 0) currentWindow = getTitle();
selectWindow("Log");
if(outputPath != "not available") {
    saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
    if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	
    }
if (nImages > 0) selectWindow(currentWindow);
}


//function returns a number in specific string format, e.g 2.5 => 02.500
//example: myStringNumber = getNumberToString(2.5, 3, 6);
function getNumberToString(number, decimalPlaces, lengthNumberString) {
numberString = "000000000000" + toString(number, decimalPlaces);  //convert to number to string and add zeros in the front
numberString = substring(numberString, lengthOf(numberString) - lengthNumberString, lengthOf(numberString)); //shorten string to lengthNumberString
return numberString;
}


//function detemins the current pixel size and unit of an image and corrects it this the given parameter
// if pixel size paramweter is <= 0 no correction of pixel size will be done
//example: correctPixelSize(pixelSizeMrf)
function correctPixelSize(pixelSizeMrf) { 
if (pixelSizeMrf <= 0) return;
getPixelSize(pixelUnit, pixelWidth, pixelHeight);
if (pixelUnit == "inches") {  // default, but wrong in CV7000 images
	print("Pixel units:", pixelUnit, "; pixel size and unit will be corrected.");
	Stack.setXUnit("um");
	Stack.setYUnit("um");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=" + pixelSizeMrf + " pixel_height=" + pixelSizeMrf + " voxel_depth=1");
	} else {
	print("Pixel size was already adapted. No correction will be done. Pixel units and sizes are:", pixelUnit, pixelWidth, pixelHeight);	
	}
}


//function reads the CV7000 .mrf file and detemins the pixel size
//example: pixelSizeMrf = readMRFfile(inputPath)
function readMRFfile(inputPath) { 
mrfFilePath = inputPath + "MeasurementDetail.mrf";
for (i = 0; i < CV7000metadataFileList.length; i++) { // try to find .mrf file in CV7000metadataFileList
	if (endsWith(CV7000metadataFileList[i], ".mrf")) {
		print("found .mrf file in meta data file list:", CV7000metadataFileList[i]);
		mrfFilePath = CV7000metadataFileList[i];
		}
	}
pixelSizeMrf = 0;  // by default initialize value that is given back by this function
doPixelSizeCorr = true;  // function variable that checks it pixel sizes are unique in .mrf, otherwise funtion will return -1 
// open .mrf file and split into line array  
if (!File.exists(mrfFilePath)) {
	print("Could not find .mrf file:", mrfFilePath, "\nPixel size could not be determined and is not automatically corrected!");
    return -1;
	} else {
	mrfFile = File.openAsString(mrfFilePath);
	lines = split(mrfFile,"\n");
	print("Reading .mrf file... length:", mrfFile.length, "; lines:", lines.length);
	// go through each line and fine dimension for each channel
	for (line = 0; line < lines.length; line++) {
    	if (matches(lines[line], "(.*Dimension.*)") ) {
    		splitLines = split(lines[line], "\"");
    		channelMrf = splitLines[1];
	    	if (pixelSizeMrf == 0) {     // on first iteration
 		   		pixelSizeMrf = splitLines[3];
    			} else {
    			if (pixelSizeMrf != splitLines[3] && doPixelSizeCorr) {     // if multiple pixel sizes or no correction 
    				print("Multiple pixel sizes in .mrf file. No correction of pixel sizes will be applied, because this could lead to mistakes...");
    				doPixelSizeCorr = false;
    				pixelSizeMrf = splitLines[3];
    				} else {                                                 // if all is normal
    				pixelSizeMrf = splitLines[3];
    				}
    			}
    		print("Channel", channelMrf, "has pixel size of", pixelSizeMrf, "um/px");
    		}  // line matches
		}  // for each line
	if (doPixelSizeCorr == false) {
		return -1;  // if multiple pixel sizes in .mrf, then return -1 as pixel size
		} else {
		return pixelSizeMrf;	
		}
	}  // if exists
}  // function
	

//function changes the CV7000 .mrf file and updates the image dimension for the cropped image and channel
//example: updateMRFfile(inputPath, cropWidth, cropHeight, channel);
function updateMRFfile(inputPath, cropWidth, cropHeight, channel) { 
mrfFilePath = inputPath + "MeasurementDetail.mrf";
channelNumber = substring(channel, 2, 3);
for (i = 0; i < CV7000metadataFileList.length; i++) { // try to find .mrf file in CV7000metadataFileList
	if (endsWith(CV7000metadataFileList[i], ".mrf") & !(endsWith(CV7000metadataFileList[i], "_original.mrf"))) {
		print("found .mrf file in meta data file list:", CV7000metadataFileList[i]);
		mrfFilePath = CV7000metadataFileList[i];
		}
	}
// open .mrf file and split into line array  
if (!File.exists(mrfFilePath)) {
	print("Could not find .mrf file:", mrfFilePath, "\n.mrf file could not be updated!");
    return -1;
	} else {
	mrfFilePathOriginal = substring(mrfFilePath, 0, lengthOf(mrfFilePath) - 4) + "_original.mrf";	
	if (!File.exists(mrfFilePathOriginal)) {
		print("Saving original .mrf file under new name:", mrfFilePathOriginal);
		File.copy(mrfFilePath, mrfFilePathOriginal);
		} else {
		print("Original .mrf file was already saved under new name:", mrfFilePathOriginal);	
		}
	mrfFile = File.openAsString(mrfFilePath);
	lines = split(mrfFile,"\n");
	//Array.show("MRF file", lines);
	print("Reading .mrf file... length:", mrfFile.length, "; lines:", lines.length);
	//for (i = 0; i < lines.length; i++) print(lines[i]);
	// go through each line and fine dimension for each channel
	for (line = 0; line < lines.length; line++) {
    	if (matches(lines[line], "(.*bts:Ch=\"" + channelNumber + "\".*)") ) {
    		//print(lines[line]);
    		splitLines = split(lines[line], "\"");
    		//for (i = 0; i < splitLines.length; i++) print(i, splitLines[i]);
    		print("Original .mrf dimensions for channel", splitLines[1], "are:", splitLines[12] + splitLines[13], "; and", splitLines[14] + splitLines[15]);
    		print("Croping reduces file size to", d2s((cropWidth * cropHeight) / (splitLines[13] * splitLines[15]) / 100, 2), "%.";
    		splitLines[13] = cropWidth;
    		splitLines[15] = cropHeight;
    		print("Updated .mrf dimensions for channel", splitLines[1], "are:", splitLines[12] + splitLines[13], "; and", splitLines[14] + splitLines[15]);
    		lines[line] = String.join(splitLines, "\"");
    		//print(lines[line]);
    		}  // line matches
		}  // for each line
	mrfFile = String.join(lines,"\n");
	File.saveString(mrfFile, mrfFilePath);	
	print("Updaed and saved the .mrf file ...");
	}  // if exists
}  // function


//function copies files (the metadata files from CV7000) to destination folder
//example: copyFiles(metadataFileList, outputPath);
function copyFiles(listOfFilePaths, outputPath) {
// go through the list of file path, get file name and copy to destination folder 
for (i = 0; i < listOfFilePaths.length; i++) {
	currentFile = substring(listOfFilePaths[i], lastIndexOf(listOfFilePaths[i], File.separator) + 1);
	File.copy(listOfFilePaths[i], outputPath + currentFile);
	print("copied:", currentFile);	
	}  //end for
}  // function		
////////////////////////////////////////   E N D    O F    M A C R O   ////////////////////////////
