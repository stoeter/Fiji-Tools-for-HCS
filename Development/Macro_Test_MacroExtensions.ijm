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
outputPath = getDirectory("temp");
Ext.saveLog(outputPath + "Log_test_macro2" + "" + ".txt");
print("Log was saved...");

print("\n=== getNumberToString ===");
number = 2.5;
Ext.getNumberToString(number, 3, 6);
print("double number as modified string is: ", number);

print("\n=== getRegexMatchesFromArray ===");
stringArrayForQuery = newArray("171020-dyes-10x_G03_T0001F005L01A01Z01C01.tif","171020-dyes-10x_G04_T0001F004L01A01Z01C02.tif","171020-dyes-10x_H05_T0001F003L01A01Z01C04.tif"); 
regexPattern = "(.*)_([A-P][0-9]{2})_(T[0-9]{4})(F[0-9]{3})(L[0-9]{2})(A[0-9]{2})(Z[0-9]{2})(C[0-9]{2}).tif$";  // also works with regex without group names
regexPattern = "(?<barcode>.*)_(?<well>[A-P][0-9]{2})_(?<timePoint>T[0-9]{4})(?<field>F[0-9]{3})(?<timeLine>L[0-9]{2})(?<action>A[0-9]{2})(?<plane>Z[0-9]{2})(?<channel>C[0-9]{2}).tif$";
Ext.getRegexMatchesFromArray(stringArrayForQuery, regexPattern, myRegexResults);
print("result string  contains all sets of unique regex matches separated by a <tab>-sign (\\t) (this sign is invisible in Log window!) and all sets of regex groups separated by double-pipe (||)...\n", myRegexResults);

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
Array.show(myRegexPluginNameArray);

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


