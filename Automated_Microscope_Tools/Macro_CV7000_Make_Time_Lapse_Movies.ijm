//CV7000-Make-Time-Lapse-Movies
macroName = "Macro_CV7000_Make_Time_Lapse_Movies";
macroShortDescription = "This macro finds all images of well positions of CV7000 and saves them as movies.";
macroDescription = "This macro saves time lapse images of CV7000 as movies." +
	"<br>CV7000 images will be opened as image sequence using well, field and acquisition number as RegEx." + 
	"<br>- Select input folder" +
	"<br>- Select ouput folder for saving files (.tif and/or .avi (select compression and frame rate))" + 
	"<br>- Multiple acquisition numbers can be selected" +
	"<br>- Actions can be saved as separate files, as concatenated series or as merged channels" +
	"<br>- If channel info is used acquisition info is ignored. " +
	"<br>HINT: keep default search term '_T0001' (first image) for finding wells, fields and acquisitions";
macroRelease = "fourth release 09-01-2018 by Martin Stöter (stoeter(at)mpi-cbg.de)";
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
print(macroName, "(" + macroRelease + ")", "\nStart:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
print(macroHelpURL);
print(generalHelpURL);

//start macro
Dialog.create("Fiji macro: " + macroName);
Dialog.addMessage("Fiji macro: " + macroName + " (Fiji-Tools-for-HCS by TDS@MPI-CBG)\n \n" + macroShortDescription + "\n \nClick 'OK' to go on, 'Cancel' to quit or 'Help' for online description.");     
Dialog.addHelp(macroHtml);
Dialog.show;

//choose folders
inputPath = getDirectory("Choose image folder... ");
outputPath = getDirectory("Choose result image folder... or create a folder");

//inputPath = "T:\\projects\\Other_small_projects\\HT-uncaging_Nadler\\cv7000images\\007EX170512A-MDCKgekoCa_20170512_161943\\007EX170512A-MDCKgekoCa\\";
//outputPath = "C:\\Users\\stoeter\\Desktop\\TempStore\\testDelete\\";
//inputPath = "C:\\Users\\stoeter\\Desktop\\movies\\200625-AH35-Uptk-Movie-GFP-siGlo-AH35_20200626_120658 C04\\200625-AH35-Uptk-Movie-GFP-siGlo-AH35\\";
//outputPath = "C:\\Users\\stoeter\\Desktop\\movies\\200625-AH35-Uptk-Movie-GFP-siGlo-AH35_20200626_120658 C04\\";

printPaths = "inputPath = \"" + inputPath + "\";\noutputPath = \"" + outputPath + "\";";
print(printPaths);
tempLogFileNumber = 1;
while (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) tempLogFileNumber ++; //find last tempLog file to prevent overwriting of log 

//initialize => default settings
run("Set Measurements...", "area mean standard min integrated median stack display redirect=None decimal=3");
run("Input/Output...", "jpeg=90 gif=-1 file=.txt copy_column copy_row save_column save_row");	
run("Close All");
run("Fiji-Tools-for-HCS-plugin");   // initialize plugin Fiji-Tools-for-HCS-plugin
Ext.getMacroExtensionVersion();

////////////////////////////////        M A C R O   C O D E         /////////////////////////////// 
displayFileList = true;                                                 //shall array window be shown? 

// use getRegexMatchesFromArray funtion from Fiji-Tools-for-HCS-plugin to find unique values in stings
//regexPattern = "(?<barcode>.*)_(?<well>[A-P][0-9]{2})_(?<timePoint>T[0-9]{4})(?<field>F[0-9]{3})(?<timeLine>L[0-9]{2})(?<action>A[0-9]{2})(?<plane>Z[0-9]{2})(?<channel>C[0-9]{2}).tif$";
regexPattern = "(?<barcode>.*)_(?<wellField>[A-P][0-9]{2}_T0001F[0-9]{3})(?<timeLineAction>L[0-9]{2}A[0-9]{2})(?<plane>Z[0-9]{2})(?<channel>C[0-9]{2}).tif$";
regexResults = inputPath;   // hand over path and file list will be loaded on Java/plugin side
//regexResults = "";  //hand over nothing and plugin will process the fileList
fileList = newArray(1);  // define array variable if not present yet, otherwise comment out
Ext.getRegexMatchesFromArray(fileList, regexPattern, regexResults);   // result string contains all sets of unique regex matches separated by a <tab>-sign (\\t) and all sets of regex groups separated by double-pipe (||)
regexGroupArray = split(regexResults, "||");   // split groups into an array using the (||) 
// by definition the first array contains the named groups of the regex
groupArray = split(regexGroupArray[0], "\t");
Array.print(groupArray);
// split each group of regex matches into an array using the (\\t)	
for (currentGroup = 1; currentGroup < regexGroupArray.length; currentGroup++) {
	currentRegexArray = split(regexGroupArray[currentGroup], "\t");
	print("regex group", groupArray[currentGroup - 1] + ":");
	Array.print(currentRegexArray);
	//if(displayFileList) Array.show("List of unique " + groupArray[currentGroup - 1], currentRegexArray);
	}
uniqueWellFields = split(regexGroupArray[2], "\t");
uniqueChannels = split(regexGroupArray[5], "\t");
uniqueTimeLineActions = split(regexGroupArray[3], "\t");

regexPattern = "(?<timeLine>L[0-9]{2})(?<action>A[0-9]{2})$";
Ext.getRegexMatchesFromArray(uniqueTimeLineActions, regexPattern, regexResults); 
regexGroupArray = split(regexResults, "||");   // split groups into an array using the (||) 
// by definition the first array contains the named groups of the regex
groupArray = split(regexGroupArray[0], "\t");
Array.print(groupArray);
// split each group of regex matches into an array using the (\\t)
for (currentGroup = 1; currentGroup < regexGroupArray.length; currentGroup++) {
	currentRegexArray = split(regexGroupArray[currentGroup], "\t");
	print("regex group", groupArray[currentGroup - 1] + ":");
	Array.print(currentRegexArray);
	//if(displayFileList) Array.show("List of unique " + groupArray[currentGroup - 1], currentRegexArray);
	}
uniqueActions = split(regexGroupArray[2], "\t");
uniqueTimeLines = split(regexGroupArray[1], "\t");
		
if(displayFileList) {
	Array.show("List of unique values found by regex...", uniqueWellFields, uniqueChannels, uniqueTimeLineActions, uniqueActions, uniqueTimeLines);
	waitForUser("Take a look at the list windows...");  //give user time to analyse the lists  
}

useActionsBooleanLists = newArray(uniqueActions.length);
useChannelsBooleanLists = newArray(uniqueChannels.length);

// settings for move generation
availableTifOptions = newArray("No .tif", "16-bit");
availableAVIOptions = newArray("No .avi", "None", "JPEG", "PNG");
framesPerSec = 5;
saveChannelsSeparately = true;
availableAcquisitonOptions = newArray("Keep separately", "Concatenate as series", "Merge as channels");
availableTimeLineOptions = newArray("Ignore time lines", "Process time lines separately");
ignoreActionsUseChannels = false;
doBleachCorrection = false;
make8bit = false;

Dialog.create("Settings for movie generation");
Dialog.addChoice("Save as .tif?", availableTifOptions, availableTifOptions[1]);
Dialog.addChoice("Save as .avi (compression)?", availableAVIOptions, availableAVIOptions[0]);
Dialog.addNumber("Frames per seconds?", framesPerSec);
Dialog.addMessage("Select the acquisition numbers to use:");
for (currentAction = 0; currentAction < uniqueActions.length; currentAction++) Dialog.addCheckbox("Use acquisition " + uniqueActions[currentAction], true);
Dialog.addCheckbox("Save as channels separately?", saveChannelsSeparately);
Dialog.addChoice("How to treat multiple actions/channels?", availableAcquisitonOptions);
Dialog.addChoice("How to treat multiple time lines?", availableTimeLineOptions);
Dialog.addCheckbox("Use channels instead of acquisitions?", ignoreActionsUseChannels);
Dialog.addCheckbox("Make bleach correction?", doBleachCorrection);
//Dialog.addCheckbox("Adjust contrast and make 8-bit?", make8bit);
Dialog.addCheckbox("Hide image display?", true);
Dialog.show(); 
saveTif = Dialog.getChoice();
saveAvi = Dialog.getChoice();
framesPerSec = Dialog.getNumber();
for (currentAction = 0; currentAction < uniqueActions.length; currentAction++) {
	useActionsBooleanLists[currentAction] = Dialog.getCheckbox();
	print("Action -", uniqueActions[currentAction], ":", useActionsBooleanLists[currentAction]);
	}
saveChannelsSeparately = Dialog.getCheckbox();	
acquisitonOption = Dialog.getChoice();
timeLineOption = Dialog.getChoice();
ignoreActionsUseChannels = Dialog.getCheckbox();
doBleachCorrection = Dialog.getCheckbox();
//make8bit = Dialog.getCheckbox();
hideImages = Dialog.getCheckbox();
print("save movie as .tif -" + saveTif + "- and as .avi -" + saveAvi + "- with", framesPerSec , "frames per second"); 
print("Treat actions:" + acquisitonOption + ", treat time lines:" + timeLineOption, ", ignore acquisition and use channel info:", ignoreActionsUseChannels); 
print("hide images", hideImages); 

if (ignoreActionsUseChannels) {
	Dialog.create("Settings for movie generation");
	Dialog.addMessage("Ignoring acqusitions, channel info will be used...");
	Dialog.addMessage("Select the channels to use:");
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) Dialog.addCheckbox("Use acquisition " + uniqueChannels[currentChannel], true);
	Dialog.show(); 
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) {
		useChannelsBooleanLists[currentChannel] = Dialog.getCheckbox();
		print("Channel -", uniqueChannels[currentChannel], ":", useChannelsBooleanLists[currentChannel]);
		}
	}	

if (doBleachCorrection) {
	//run("Bleach Correction", "correction=[Simple Ratio] background=10");  run("Bleach Correction", "correction=[Exponential Fit]");  run("Bleach Correction", "correction=[Histogram Matching]");
	availableBleachModels = newArray("Simple Ratio","Exponential Fit", "Histogram Matching");
	bleachModelParameter = 0;
	Dialog.create("Settings for bleach correction");
	Dialog.addMessage("Select the bleach correction to apply:");
	Dialog.addMessage("Simple Ratio: speed medium, needs background parameter\nExponential Fit: speed fast, no parameter needed\nHistogram Matching: very slow on 16bit, no parameter");
	Dialog.addChoice("Bleach correction model:", availableBleachModels);
	Dialog.addNumber("Background value (only Simple Ratio)?", bleachModelParameter);
	Dialog.show(); 
	bleachModel = Dialog.getChoice();
	bleachModelParameter = Dialog.getNumber();
	if (bleachModel == "Simple Ratio") {
		bleachModelParameter = " background=" + bleachModelParameter;
		} else {
		bleachModelParameter = "";	
		}
	print("Bleaching applied, Model:" + bleachModel + bleachModelParameter); 	
	}

//set variables according to user dialogs
contrastValueArray = newArray(100,355,100,355,100,355,100,355,100,355);  //vector of alternating min-max contrast values => newArray(ch1-min,ch1-max,ch2-min,ch2-max,ch3-min, ...)
//fileEndArray = newArray("C01.tif","C02.tif","C03.tif","C04.tif");  //vector of a file endings of individual channels
channelToRGBArray = newArray("3","2","1");   //vector of colors (RGB channel numbers) assigned to file endings
contrastValueArray = newArray(50,2000,50,1200,50,2000,100,355,100,355);  //vector of alternating min-max contrast values => newArray(ch1-min,ch1-max,ch2-min,ch2-max,ch3-min, ...)
channelToRGBArray = newArray("2","1","3");   //vector of colors (RGB channel numbers) assigned to file endings
//if (make8bit) {
if (saveAvi != availableAVIOptions[0]) {  // if .avi is saved => 8-bit needed or tife saved as 8-bit
	print("To save .avi intensities of channels will be adjusted ..."); 
	print("for RGB merges colors have these channel numbers: Red = 1, Green = 2, Blue = 3");
	fileTag = "_RGB";
	Dialog.create("Set contrast values for RGB merge");
	Dialog.addMessage("Red = 1, Green = 2, Blue = 3");
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) {
		Dialog.addMessage("--------------------------------------------");
		Dialog.addChoice("Color of channel ends with " + uniqueChannels[currentChannel] + ":", channelToRGBArray, channelToRGBArray[currentChannel]);	 //which channel is which color in RGB
		Dialog.addNumber("Set minimum intensity channel " + uniqueChannels[currentChannel] +":", contrastValueArray[currentChannel * 2]);	//set value for min
		Dialog.addNumber("Set maximum intensity channel " + uniqueChannels[currentChannel] +":", contrastValueArray[currentChannel * 2 + 1]);	//set value for max
		}
	Dialog.show();
	for (currentChannel = 0; currentChannel < uniqueChannels.length; currentChannel++) {
		channelToRGBArray[currentChannel] = Dialog.getChoice();
		contrastValueArray[currentChannel * 2] = Dialog.getNumber();
		contrastValueArray[currentChannel * 2 + 1]  = Dialog.getNumber();
		print("channel " + uniqueChannels[currentChannel] + ": ends with", uniqueChannels[currentChannel], "is assigned to RGB channel", channelToRGBArray[currentChannel] + ", contrast min =", contrastValueArray[currentChannel * 2], "and max =", contrastValueArray[currentChannel * 2 + 1]);  
		}
	} 

//start processing...
setBatchMode(hideImages);
for (currentWellField = 0; currentWellField < uniqueWellFields.length; currentWellField++) {
	showProgress(currentWellField / uniqueWellFields.length);
	
	// open well field data one after the other...
	currentWell = substring(uniqueWellFields[currentWellField], 0, 3);
	currentField = substring(uniqueWellFields[currentWellField], lengthOf(uniqueWellFields[currentWellField])-4, lengthOf(uniqueWellFields[currentWellField]));

	mergeChannelsString = "";
	if (acquisitonOption ==  "Ignore time lines") {
		uniqueTimeLines = newArray("");
		//uniqueTimeLineActions;  // combine time line with acquisitions => unique values and iteration over regex is combination of time line and acquisition (TimeLineActions)
//		if(displayFileList) {
//			Array.show("List of " + uniqueTimeLineActions.length + " unique time line acquisitions", uniqueTimeLineActions);
//			waitForUser("Take a look at the list windows...");  //give user time to analyse the lists  
//			}
		}
	if (ignoreActionsUseChannels) {
		uniqueActions = uniqueChannels;  // assumption iterate over acquisition now will iterate over channels
		useActionsBooleanLists = useChannelsBooleanLists;
		}
		
	for (currentTimeLine = 0; currentTimeLine < uniqueTimeLines.length; currentTimeLine++) {
		imageSequenceCounter = 0;
		for (currentAction = 0; currentAction < uniqueActions.length; currentAction++) {
			if (useActionsBooleanLists[currentAction]) {  // always true if acquisitions are ignores => use all channels, otherwise only selected acquisitions will be processed, deleted: | ignoreActionsUseChannels
				imageSequenceCounter++;  // only add one count if acquisition number is actually enabled and will be loaded 
				print("( " + (currentWellField+1) + " / " + uniqueWellFields.length + " ) open images with regex:", currentWell, currentField, uniqueTimeLines[currentTimeLine], uniqueActions[currentAction]);
				regexString = "(.*_" + currentWell + "_.*" + currentField + ".*" + uniqueTimeLines[currentTimeLine] + ".*" + uniqueActions[currentAction] + ".*)";
				print("regex:" + "(.*_" + currentWell + "_.*" + currentField + ".*" + uniqueTimeLines[currentTimeLine] + ".*" + uniqueActions[currentAction] + ".*)");
				IJ.redirectErrorMessages();
				run("Image Sequence...", "dir=[" + inputPath + "] filter=" + regexString + " sort");
				//waitForUser("check: " + nImages + "_" + imageSequenceCounter);
				if (nImages == imageSequenceCounter) { // see imageSequenceCounter above
					currentImage = getTitle();
					currentImage = currentImage + "_" + currentWell + "_" + currentField + "_" + uniqueTimeLines[currentTimeLine] + "_" + uniqueActions[currentAction];
					rename(currentImage);
					mergeChannelsString = mergeChannelsString + "c" + channelToRGBArray[currentAction] + "=[" + currentImage + "] ";
					//print(mergeChannelsString);
					print("opened ", nSlices, " images:", currentImage);
					} else {
					print("no images found");	// run Image Sequence silently failed...
					}

				//apply bleach correction
				if (doBleachCorrection) {
					//run("Bleach Correction", "correction=[Simple Ratio] background=10");  run("Bleach Correction", "correction=[Exponential Fit]");  run("Bleach Correction", "correction=[Histogram Matching]");
					run("Bleach Correction", "correction=[" + bleachModel + "]" + bleachModelParameter);
					close(currentImage);
					if (bleachModel == "Exponential Fit") close("y = a*"); // close plot window from exponential fit 
					}

				//set contrast
				if (saveAvi != availableAVIOptions[0]) {
					setMinAndMax(contrastValueArray[currentAction * 2], contrastValueArray[currentAction * 2 + 1]);
					//run("8-bit");
				}

				if (saveChannelsSeparately) {   // "save separete channels/acquisitions separate files"	
					if (saveTif == availableTifOptions[1]) {
						saveAs("Tiff", outputPath + currentImage + ".tif");
						print("saved", outputPath + currentImage + ".tif");
						}
					if (saveAvi != availableAVIOptions[0]) {
						run("AVI... ", "compression=" + saveAvi + " frame=" + framesPerSec + " save=[" + outputPath + currentImage + ".avi]");
						print("saved", outputPath + currentImage + ".avi");
						}
					}
				
				if (acquisitonOption == availableAcquisitonOptions[0]) {   // "Keep separate files"	...and not further use of individual images is needed (no merging, no concatinating)
					close();
					imageSequenceCounter--;  // subtract one count if no mergering is done and just the separared channels will be saved (otherwise the open images and the imageSequenceCounter does not fit)	
					} else {
					rename(currentImage);	
					}
				} //end if use acquisition / channel
			}  //end for acquistitions

		if (acquisitonOption == availableAcquisitonOptions[1]) {   // "Concatenate as series"	
			if (nImages > 1) {
				run("Concatenate...", "all_open title=Movie");
				currentImage = currentImage + "_concatenated";
				}
			}

		if (acquisitonOption == availableAcquisitonOptions[2]) {   // "Merge as channels"	
			if (nImages > 1) {
				run("Merge Channels...", mergeChannelsString + "create");  //"c1=Newfolder_C03_F001_A01 c2=Newfolder_C03_F001_A02 create");
				currentImage = currentImage + "_allChannels";
				}
			}
	
		//Save the image file
		if (nImages > 0) { //check if regex was sucessful and images could be opened
			if (saveTif == availableTifOptions[1]) {
				saveAs("Tiff", outputPath + currentImage + ".tif");
				print("saved", outputPath + currentImage + ".tif");
				}
			if (saveAvi != availableAVIOptions[0]) {
				run("AVI... ", "compression=" + saveAvi + " frame=" + framesPerSec + " save=[" + outputPath + currentImage + ".avi] ");
				print("saved", outputPath + currentImage + ".avi");
				}
			close();
			}
		}
	// replaced by plugin: saveLog(outputPath + "Log_temp_" + tempLogFileNumber +".txt");
	Ext.saveLog(outputPath + "Log_temp_" + tempLogFileNumber +".txt");		
	}  //end well fields

//print current time to Log window and save log
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec); month++;
print("Macro executed successfully.\nEnd:",year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second);
selectWindow("Log");
saveAs("Text", outputPath + "Log_"+year+"-"+month+"-"+dayOfMonth+", "+hour+"-"+minute+"-"+second+".txt");
if (File.exists(outputPath + "Log_temp_" + tempLogFileNumber +".txt")) File.delete(outputPath + "Log_temp_" + tempLogFileNumber + ".txt");  //delete current tempLog file 

/////////////////////////////////////////////////////////////////////////////////////////////
////////                             F U N C T I O N S                          /////////////
/////////////////////////////////////////////////////////////////////////////////////////////

//replaced by plugin: 
