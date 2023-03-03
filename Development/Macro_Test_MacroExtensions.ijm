print("\\Clear");

print("\n================ M A C R O E X T E N S I O N S   f o r   F I J I - T O O L S - F O R - H C S  =======================\n\n");
print("\nthis is a short introduction into the usage of the MacroExtensions written for the Fiji-Tools-For-HCS");
print("you can find this macro also in your plugin folder and check it out how the code works...");
folderOfThisMacro = getDirectory("plugins") + "Scripts" + File.separator + "Plugins" + File.separator + "Fiji-Tools-for-HCS" + File.separator + "Development" + File.separator;
print(folderOfThisMacro);

print("\n===== test macro extensions =====");
print("to use the MacroExtensions of Fiji-Tools-For-HCS you first have to call/run the plugin...");
print("run(\"Fiji-Tools-for-HCS-plugin\");");

run("Fiji-Tools-for-HCS-plugin");  //run("Fiji-Tools-ForHCS");

print("\nnow you can make use of the MacroExtensions by calling an external function using this syntax:");
print("Ext.myCoolJavaFunction(stringParameter, numberParameter, arrayParameter);");
print("see the available functions below and check out the documentation mentioned below..."); 
print("\nthe version can be recorded to Log window...");
Ext.getMacroExtensionVersion();

print("\nthe functions can be listed:");
Ext.getMacroExtensionNames();
print("\nfor further help and documentation see here:");
print("https://github.com/stoeter/FijiToolsForHCSplugin/wiki");

print("\n=== saveLog ===");
run("Blobs (25K)");        // test if active window is an image disturbes saving the log
selectWindow("blobs.gif");
outputPath = getDirectory("temp");
Ext.saveLog(outputPath + "Log_test_macro2" + "" + ".txt");
print("Log was saved here:", outputPath + "Log_test_macro2" + "" + ".txt");
close("blobs.gif");

print("\n=== getNumberToString ===");
number = 2.5;
Ext.getNumberToString(number, 3, 6);
print("double number as modified string is: ", number);

print("\n=== getRegexMatchesFromArray ===");
stringArrayForQuery = newArray("171020-dyes-10x_G03_T0001F005Z01C01.tif","171020-dyes-10x_G04_T0001F004L01A01Z01C02.tif","171020-dyes-10x_H05_T0001F003L01A01Z01C04.tif"); 
regexPattern = "(.*)_([A-P][0-9]{2})_(T[0-9]{4})(F[0-9]{3})(L[0-9]{2})(A[0-9]{2})(Z[0-9]{2})(C[0-9]{2}).tif$";  // also works with regex without group names
regexPattern = "(?<barcode>.*)_(?<well>[A-P][0-9]{2})_(?<timePoint>T[0-9]{4})(?<field>F[0-9]{3})(?<timeLine>L[0-9]{2})(?<action>A[0-9]{2})(?<plane>Z[0-9]{2})(?<channel>C[0-9]{2}).tif$";
Ext.getRegexMatchesFromArray(stringArrayForQuery, regexPattern, myRegexResults);
// third parameter (myRegexResults) is an optional directory. Using optional path to list files and array (first parameter) will be ignored!");
print("result string contains all sets of unique regex matches separated by a <tab>-sign (\\t) (this sign is invisible in Log window!) and all sets of regex groups separated by double-pipe (||)...\n", myRegexResults);

print("\nsets of regex groups can be split into an array using the (||) and the split() command from IJ-macro language...");	
myRegexGroupArray = split(myRegexResults, "||");
Array.print(myRegexGroupArray);
print("by definition the first array contains the named groups of the regex: " + myRegexGroupArray[0]);

print("\nsets of regex matches of a single group can be further split into an array using the (\\t) and the split() command from IJ-macro language...");	
myRegexWellArray = split(myRegexGroupArray[2], "\t");
Array.print(myRegexWellArray);
print("here are my individual well: " + myRegexWellArray[0]);
Array.show(myRegexWellArray);

print("\nOPTION: if the resultstring (=3 parameter) is an existing path, then all file names will be read and the regular expression is applied on them... ");
regexPattern = "(?<pluginName>.*)-(?<version>\\d+\\.\\d+.\\d+).jar$";
optionalPath = getDirectory("plugins");
myRegexResults = optionalPath;
Ext.getRegexMatchesFromArray(stringArrayForQuery, regexPattern, myRegexResults);
print("result string  contains all sets of unique regex matches separated by a <tab>-sign (\\t) (this sign is invisible in Log window!) and all sets of regex groups separated by double-pipe (||)...\n", myRegexResults);
myRegexGroupArray = split(myRegexResults, "||");
myRegexPluginNameArray = split(myRegexGroupArray[1], "\t");
//Array.show(myRegexPluginNameArray);

print("\nOPTION: use resultstring (=3 parameter) as existing path, apply regex and open all images... see also HCS-Tools macro 'Import_Image_Sequence_Recursive' ");
// getRegexMatchesFromArray for regex on file lists 
// 1) define your path and pass it onto the result variable (if result variable is an existing path, then all file names will be read and the regular expression is applied on them...)
optionalPath = getDirectory("imagej") + "images";
print(optionalPath);
//optionalPath = getDirectory("macros");  // enable this to mimic that no files were found
myRegexResults = optionalPath;
// 2) define your regex
regexPattern = "(?<paths>.*.png$)";
// 3) define you regex query => here empty because the regex will be applied on the files found in given path
stringArrayForQuery = newArray(0);
// 4) launch the regex query
Ext.getRegexMatchesFromArray(stringArrayForQuery, regexPattern, myRegexResults);
// 5) since result is passed back as single string, regex groups can be split into an array using the (||) ...");
myRegexGroupArray = split(myRegexResults, "||");
print(myRegexResults);
if(myRegexGroupArray.length < 2) {
	print("no images found");
	waitForUser("No images found!");
	} else {
// 6) first group is regex query names (here just "paths"), second group (=[1]) is array of paths, make absolute paths
	pathArray = split(myRegexGroupArray[1], "\t");
	for (i = 0; i < pathArray.length; i++) {
		pathArray[i] = optionalPath + File.separator + pathArray[i];
		}
	Array.show(pathArray);
	pathArrayForStackListFile = String.join(pathArray, "\n");
// 7) save the list of paths in a FIJI temp folder (tab separated elements need to be separated by line breaks)		
	tempFile = getDirectory("temp") + "listOfPaths.txt";
	print("saved list of paths temporarily here:", tempFile);
	File.saveString(pathArrayForStackListFile, tempFile);
// 7) open file list generated from regular expression	
	run("Stack From List...", "open=" + tempFile);
	}
/*
print("\n=== getFileListSubfolder ===");
myFileListFromSubfolders = "display";
Ext.getFileListSubfolder(optionalPath, myFileListFromSubfolders);  // optional path is directory of plugins and strings "display", "1" or true (boolean) enable showing array in a window
myFileListFromSubfolders = split(myFileListFromSubfolders, "\t");
//Array.show(myFileListFromSubfolders);

print("\n=== setDialogFilterMultiple ===");
//set variables for filter declarations setDialogFilterMultiple()
fileExtension = ".tif";                                                           //pre-definition of extension
filterStrings = newArray(".jar","Plugin","Fiji_");         
availableFilterTerms = newArray("no filtering", "include", "exclude");            //dont change this
filterTerms = newArray("include", "include", "exclude");                          //pre-definition of filter types 
displayFileList = true;                                                           //shall array window be shown? 
displayFileList = 0;      
Ext.setDialogFilterMultiple(fileExtension, Array.concat(filterStrings, availableFilterTerms, filterTerms), resultStringArray, displayFileList);    // strings "display", "1" or true (boolean) enable showing array in a window
filtersettings = split(resultStringArray, "\t");
Array.print(filtersettings);
print("Image file filter:", filtersettings[filtersettings.length/3 *2 + 0],filtersettings[0] + ";",filtersettings[filtersettings.length/3 *2 + 1],filtersettings[1] + ";",filtersettings[filtersettings.length/3 *2 + 2],filtersettings[2]);
displayFileList = parseInt(displayFileList);   //if (displayFileList) print("display option can be used now as boolean");
print("File extension filter:", fileExtension, "; display option is:", displayFileList);

print("\n=== getFilteredListMultiple ===");
//for setting variables for filter declarations see above: setDialogFilterMultiple()
resultStringArray = false;                                                            // this variable captures the returned list, but also sends optional filter setting to java function; default is "subsequent", false or "0"; option is "additional", true, or "1" ... see below...
// if resultStringArray = true, then additional filtering is possible (e.g. file names containing "H08" and "D04" => H08 and D04 in list
// if resultStringArray = false, then subsequent filtering is possible (e.g. file names containing "controls" and "positive" => positive controls, but not negative controls in list!
// for testing additional filtering activate the varaible definitions...
//resultStringArray = "additional";                                      
//filterStrings = newArray("3D","2.0.1","Fiji_");                                //pre-definition of strings to filter
//filterTerms = newArray("include", "include", "include");                       //pre-definition of filter types 
//filterSettings = Array.concat(filterStrings, availableFilterTerms, filterTerms);     //the filter settings are 3 arrays and must be concatenated to a single array and then uses a 2nd parameter  
//Ext.getFilteredListMultiple(myFileListFromSubfolders, Array.concat(filterStrings, availableFilterTerms, filterTerms), resultStringArray, "display");    // strings "display", "1" or true (boolean) enable showing array in a window
Ext.getFilteredListMultiple(myFileListFromSubfolders, filtersettings, resultStringArray, displayFileList);  
*/
print("\n=== getFilteredList ===");
stringArrayForQuery = newArray("171020-dyes-10x_G03_T0001F005Z01C01.tif","171020-dyes-10x_G04_T0001F004L01A01Z01C02.jpg","171020-dyes-10x_H05_T0001F003L01A01Z01C04.tif"); 
Array.print(stringArrayForQuery);
resultStringArray = "";
Ext.getFilteredList(stringArrayForQuery, ".tif", true, resultStringArray);    // strings "display", "1" or true (boolean) enable showing array in a window
//resultStringArray = split(resultStringArray, "\t");
print("after filtering for :", ".tif");
print(resultStringArray);
filteredList = split(resultStringArray, "\t");
Array.print(filteredList);
Ext.getFilteredList(stringArrayForQuery, "G04", true, resultStringArray);
print("after filtering for :", "G04");
filteredList = split(resultStringArray, "\t");
Array.print(filteredList);


print("\n============= M A C R O E X T E N S I O N S  :  t h e  J A V A S I D E   f o r   F I J I - T O O L S - F O R - H C S  ===================\n\n");
print("\nthe Java code of the FijiToolsForHCSplugin you can find here:");
print("https://github.com/stoeter/FijiToolsForHCSplugin/blob/master/src/main/java/de/mpicbg/tds/FijiToolsForHCSplugin.java");
print("\nfor examples and documentation of the Java code of the MacroExtensions look here:");
print("https://imagej.nih.gov/ij/plugins/download/Image5D_Extensions.java");
print("https://github.com/jayunruh/Jay_Plugins2/blob/master/PlotWindow_Extensions_jru_v1.java");

print("\n=== testStringArray ===");
myArray = newArray("2","3","6");
//print("doubleNumber (asString) is :",doubleNumber);
Ext.testStringArray(returnString,myArray);
print("string array (as one String) is: ", returnString);
myNewArray = split(returnString, "\t");
print("array as strings...");	
Array.print(myNewArray);
Array.show(myNewArray);

print("\n=== testDoubleArray ===");
returnString = "someString";
myArray = newArray(2,3.1,6.3663553);
Ext.testDoubleArray(returnString,myArray);
print("double array (as one String) is: ", returnString);
myNewArray = split(returnString, "\t");
print("array as strings (these are not numbers get)...");	
Array.print(myNewArray);
for (i=0; i < myNewArray.length; ++i) {
	myNewArray[i] = parseFloat(myNewArray[i]);
	}
print("array as doubles...");	
Array.print(myNewArray);	

