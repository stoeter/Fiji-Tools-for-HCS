//CV7000-Z-Projection
macroName = "CV7000-Z-Projection";
macroShortDescription = "This macro opens CV7000 images of a well-field-channel and does a z projection.";
macroDescription = "This macro reads single CV7000 images of a well as .tif ." +
	"\nThe chosen folder will be searched for images including subfolders." +
	"\nOption to select several input folders for batch processing at end of GUI." +
	"\nAll images of a unique well, field and channel are opened and projected." +
	"\nAll z-projection methods selectable. Pixel size can be automatically corrected." +
	"\nProjection and / or image stack files (to subfolder 'stack') can be saved (can handle stacks larger than 100 (e.g. Z100))." +
	"\nOption to copy CV7000 meta data files to output folder.";
macroRelease = "2.0.2_240304";
macroAuthor = "by Martin Stöter (stoeter(at)mpi-cbg.de)";
generalHelpURL = "https://github.com/stoeter/Fiji-Tools-for-HCS/wiki";
macroHelpURL = generalHelpURL + "/" + macroName;

//===== Script Parameters =====
#@ String  spMacroTitle      (label="<html><font color=#EE1111><em><b>===== Macro CV7000 Z-Projection =====</b></em></font></html>", visibility=MESSAGE, required=false, description="This macro opens CV7000 images of a well-field-channel and does a Z projection.\nFiji-Tools-for-HCS by TDS@MPI-CBG, Version 2.0.1_231124") 
#@ String  spMacroSubTitle   (label="<html><font color=#EE1111><em>----- use mouse-roll-over for help ----- </em></font></html>", visibility=MESSAGE, required=false, description="<html>Essential configuration in <font color=#FF6600>orange</font>. Non-persistent default values in <html><font color=#000077>dark blue</font>.<br>For further help and hints see also in Log window...</html>") 
// image input and output
#@ String  spInput           (label="<html><b>Select one or multiple CV7000 folders:</b></html>", visibility=MESSAGE, required=false, description="Select CV7000 measurement folder, subfolders are included.\nOutput folder does not need to be specified") 
#@ File[]  inputPaths        (label="<html><font color=#FF6600>Input folders:</font></html>", style="both", description="For multiple folders hold SHIFT / STRG ...") 
#@ File    outputPath        (label="<html><font color=#000077>Specific output folder?</font></html>", style="directory", required=false, persist=false, description="Not essential. Per default projections will be saved in subfolder 'Zprojection' of selected input folder.\nChange default output folder name selection 'Projection tag' as 'customize own tag'") 
// image file filter
#@ String  spImageFileFilter (label="<html><b>Image file filter - Define the files to be processed ...</b></html>", visibility=MESSAGE, required=false, description="This feature helps to shape and filter the file list to obtain a specific set of image files") 
#@ String  fileExtension     (label="<html><font color=#000077>Files should have this extension:</font></html>", value=".tif", persist=false, description="Enter an image extension (like '.tif') to e.g. exclude file types other than CV7000 meta data files") 
#@ String  spDefineFilter    (label="<html>Define filter for files:</html>", visibility=MESSAGE, required=false, description="Below three consecutive filters can be configured to include or exclude files based on a specific text tags")
#@ String  filterStrings0    (label="1) Filter this text from file list:", value="", description="Enter text to specify file names (1)")
#@ String  filterTerms0      (label="<html><font color=#000077>1) Files with text are included/excluded?</font></html>", choices={"no filtering", "include", "exclude"}, persist=false, style="radioButtonHorizontal", description="Choose to include or exclude files with specific text (1)") 
#@ String  filterStrings1    (label="2) Filter this text from file list:", value="", description="Enter text to specify file names (2)") 
#@ String  filterTerms1      (label="<html><font color=#000077>2) Files with text are included/excluded?</font></html>", choices={"no filtering", "include", "exclude"}, persist=false, style="radioButtonHorizontal", description="Choose to include or exclude files with specific text (2)") 
#@ String  filterStrings2    (label="3) Filter this text from file list:", value="", description="Enter text to specify file names (3)") 
#@ String  filterTerms2      (label="<html><font color=#000077>3) Files with text are included/excluded?</font></html>", choices={"no filtering", "include", "exclude"}, persist=false, style="radioButtonHorizontal", description="Choose to include or exclude files with specific text (3)") 
#@ Boolean displayFileList   (label="<html><font color=#000077>Display the file lists?</font></html>", value=false, persist=false, description="If checked the file lists are displyed at each step of the Image file filter")                      //if check file lists will be displayed
#@ Boolean displayMetaData   (label="<html><font color=#000077>Display unique values of meta data?</font></html>", value=false, persist=false, description="If checked unique values of meta data from file names (like wells, fields, channel, etc.) are displyed in separate windows")    //if check file lists will be displayed
//set projection type
#@ String  spZprojection     (label="<html><b>Z-projection - Define settings ...</b></html>", visibility=MESSAGE, required=false, description="Customize general Z-projection settings, image file list specific Z-projection settings can be set later...") 
#@ String  projectionType    (label="Projection type:", choices={"Max Intensity", "Sum Slices", "Average Intensity", "Min Intensity", "Standard Deviation", "Median"}, style="listBox", description="Select mathematical operation per pixel in Z") 
#@ String  projectionFileTag (label="Projection tag:", choices={"00", "all", "max", "min", "avg", "customize own tag"}, style="listBox", description="Customize file tag for projected image (or stack), e.g. ..Z01.. -> ..Z00.. or -> ..Zall.., or ... customize default output folder name (customize own tag)") 
#@ Boolean saveProjection    (label="<html><font color=#000077>Save Z-projection?</font></html>", value=true, persist=false, description="If checked projected files will be saved") 
#@ Boolean saveStack         (label="<html><font color=#000077>Save Z-stack in subfolder?</font></html>", value=false, persist=false, description="If checked images will be saved as a multi-page image stack in one file") 
//set projection type
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
defaultOutputfolderName = "Zprojection";
// if no selection in script parameters, then it is output path is ImageJ path!?? Set variavle outputPathSelected then to 0, it is 1 when an outputPath was selected
//print((replace(outputPath + File.separator, File.separator, "/") == replace(getDir("imagej") , File.separator, "/")));
//outputPathSelected = !( replace(outputPath + File.separator, File.separator, "/") == replace(getDir("imagej") , File.separator, "/") );  // cannot compare strings with backslash!???
//if (outputPath == 0) outputPathSelected = false;  // if nothing is selected in GUI then the return value will be 0, not NA or null (see here: https://forum.image.sc/t/issue-with-script-parameter-file-in-fiji-when-not-selected-and-the-getdir-imagej-function/91420)
//print(outputPathSelected);

//set output projection folder name
if (projectionFileTag == "customize own tag") { // user defined output folder name
	Dialog.create("Set specific projection tag options");
	Dialog.addString("Projection file tag:", "00");
	Dialog.addString("Change default output folder name?", defaultOutputfolderName);
	Dialog.show();
	projectionFileTag = Dialog.getString();
	defaultOutputfolderName = Dialog.getString();
	print("Default output folder was set to:", defaultOutputfolderName);
	}
					
if ( (inputPaths.length > 1) || outputPath == 0 ) {     // if nothing is selected in GUI then the return value of outpuPath will be 0 (see above)
	print("Selected output path will be ignored and ouput folders will be generated automatically in each input folder");
	outputPathSelected = false;
	} else {
	outputPath = outputPath + File.separator;
	print("Output path:", outputPath,"");
	outputPathSelected = true;
	}

//set log file number
tempLogFileNumber = 1;
if(outputPath != "not available") while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min centroid center shape integrated median display redirect=None decimal=3");
run("Input/Output...", "jpeg=95 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
//run("Color Balance...");

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 

//set variables
var zPlaneDigitProblem = 0;  // this will be only used and set to 1 if stack is saved and number of z planes are > 99, thereby 3-digits => e.g. Z100
var CV7000metadataFileList = newArray(0);                                     //initialize - list of files (metadata forom CV7000) that will be copied to outoutPath

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
        //outputPath = substring(inputPaths[currentFolder], 0, lastIndexOf(inputPaths[currentFolder], File.separator)) + File.separator + "Zprojection" + File.separator;
        outputPath = inputPath + defaultOutputfolderName + File.separator;
        File.makeDirectory(outputPath);
        print("New output folder -> made folder for projection files: " + outputPath);  //to log window
        }
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
    if (fileList.length == 0) exit("No files to process"); 
    //print("removing correction files from file list containing text", defaultFilterStrings[0], defaultFilterStrings[1], defaultFilterStrings[2]);
    wellList = getUniqueWellListCV7000(fileList, displayMetaData);
    wellFieldList = getUniqueWellFieldListCV7000(fileList, displayMetaData);
    fieldList = getUniqueFieldListCV7000(fileList, displayMetaData);
    channelList = getUniqueChannelListCV7000(fileList, displayMetaData);
    //print(wellList.length, "wells found\n", wellFieldList.length, "well x fields found\n", fieldList.length, "fields found\n", channelList.length, "channels found\n");
    
    if (currentFolder == 0) { // in first iteration check stack size and options
    	stackSize = fileList.length / wellFieldList.length / channelList.length;
    	print("Assuming stacks with ", stackSize, "planes. Please check if this is correct!");
		if (displayFileList || displayMetaData) waitForUser("Take a look at the list windows...");  //give user time to analyse the lists 
    	
    	//set projection type
		Dialog.create("Set specific projection options");
		Dialog.addMessage("Set projection dimension");
		Dialog.addNumber("Lowest plane:", 1);
		Dialog.addNumber("Highest plane:", stackSize);
		Dialog.show();
		Zstart = Dialog.getNumber();
		Zstop = Dialog.getNumber();

    	} else {  // from second iteration on...
		print("Calculated number of planes in stacks is ", fileList.length / wellFieldList.length / channelList.length);
       	print("Using settings of first iteration (first selected folder)...");        
        }

	print("Selected projection type:", projectionType, "starting from plane", Zstart, "until plane", Zstop);
    print("Saving the Z-projection (0=false, 1=true):", saveProjection, "saving the stack:", saveStack, "copy CV700 meta data files:", copyMetaDataFiles, "using file tag:", projectionFileTag);
	saveLog(outputPath + "Log_temp_" + tempLogFileNumber + ".txt"); 

    if (saveStack) {
        File.makeDirectory(outputPath + "stack");
        print("made folder for saving stack files: " + outputPath + "stack" + File.separator);  //to log window
        }	
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
            if (saveStack) wellChannelFileList = correctCV7000zPlaneDigitProblem(wellChannelFileList);
            
            //now open all files (wellChannelFileList) that belong to one wellField in one channel
            for (currentFile = 0; currentFile < wellChannelFileList.length; currentFile++) {
                //image sequence & regEx would be possible, but it seems to be slow: run("Image Sequence...", "open=Y:\\correctedimages\\Martin\\150716-wormEmbryo-Gunar-test2x3-lowLaser_20150716_143710\\150716-wormEmbryo-6half-days-old\\ file=(_B03_.*C01) sort");
                IJ.redirectErrorMessages();
                if (File.exists(wellChannelFileList[currentFile])) {
                    open(wellChannelFileList[currentFile]);
                    currentImage = getTitle();
                    print("opened (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
                    if (doPixelSizeCorr) correctPixelSize(pixelSizeMrf);   // do pixel size / unit correction
                    } else {
                    print("file not found (" + (currentFile + 1) + "/" + wellChannelFileList.length + "):", wellChannelFileList[currentFile]);  //to log window
                    }
                showProgress(currentFile / wellChannelFileList.length);
                showStatus("processing" + fileList[currentFile]);
                } //end for all images per channel	
            //waitForUser("done");	
            if (nImages > 1) {
                run("Images to Stack", "name=Stack title=[] use");
                outputFileName = substring(currentImage, 0, lengthOf(currentImage) - 9 - zPlaneDigitProblem) + projectionFileTag + substring(currentImage, lengthOf(currentImage) - 7, lengthOf(currentImage));   // this should handle the 2-digit and 3-digit file names
                //outputFileName = substring(currentImage, 0, lengthOf(currentImage) - 10                    ) + projectionFileTag + substring(currentImage, lengthOf(currentImage) - 7,lengthOf(currentImage)); // here file name is 3 digit  (e.g. Z234)
                if (saveProjection) {
                    run("Z Project...", "start=" + Zstart + " stop=" + Zstop + " projection=[" + projectionType + "]");
                    saveAs("Tiff", outputPath + outputFileName);
                    print("saved projection as " + outputPath + outputFileName);  //to log window	
                    close();  //Z projection
                    }			
                if (saveStack) {
                    selectWindow("Stack"); //stack
                    saveAs("Tiff", outputPath + "stack" + File.separator + outputFileName);
                    print("saved image stack as " + outputPath + "stack" + File.separator + outputFileName);  //to log window
                    }
                }  //end if images are open
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
    selectWindow("Log");
    if(outputPath != "not available") {
        saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", h"+hour+"-m"+minute+"-s"+second+".txt");
        if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 	
        }
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

//function checks if CV7000 has 3 digits (Z01-Z99) or also 3 digits (from Z100...) in file name
//example: wellChannelFileList = correctCV7000zPlaneDigitProblem(wellChannelFileList);
function correctCV7000zPlaneDigitProblem(wellChannelFileListFunction) { 
	// Array.show("wellChannelFileList", wellChannelFileList);
	// make new array and store lenght of file names
	wellChannelFileNamelength = newArray(wellChannelFileListFunction.length);
	for (i = 0; i < wellChannelFileListFunction.length; i++) {
		wellChannelFileNamelength[i] = lengthOf(wellChannelFileListFunction[i]);
		}
	// Array.show("wellChannelFileNamelength", wellChannelFileNamelength);	
	Array.getStatistics(wellChannelFileNamelength, min, max, mean, stdDev);
	// if length min vs max differes in 1, then there are 2 and 3 digit file names. Now put 2 digit in one array and 3 digit file names in a second array
	if (max == min + 1) {
		print("found 2- and 3-digit format in CV7000 file names. File names will be sorted correctly. Length (min, max):" , min , max);
		zPlaneDigitProblem = 1;
		wellChannelFileListTwoDigits = newArray(0);
		wellChannelFileListThreeDigits = newArray(0);
		for (i = 0; i < wellChannelFileListFunction.length; i++) {
			if (wellChannelFileNamelength[i] ==  min) {
				wellChannelFileListTwoDigits[wellChannelFileListTwoDigits.length] = wellChannelFileListFunction[i];
				} else {
				wellChannelFileListThreeDigits[wellChannelFileListThreeDigits.length] = wellChannelFileListFunction[i];
				}
			}
		// finally concatenate both arrays to optain Z01-Z99, and Z100 to ... NEEDS to be extended to 4 digits at soma point...	
		wellChannelFileListFunction = Array.concat(wellChannelFileListTwoDigits, wellChannelFileListThreeDigits);
		//Array.show("wellChannelFileNamelength NEW", wellChannelFileList);			
		}
	if (max > min + 1) {
		print("found 2- and more-digit formats in CV7000 file names. File names will not be sorted correctly. Length (min, max):" , min , max);	
		waitForUser("WARNING!","Found 2- and more-digit formats in CV7000 file names. File names will not be sorted correctly!");
		}
	return wellChannelFileListFunction;
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











