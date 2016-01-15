//Check-Fiji-Installation
macroName = "Check-Fiji-Installation";
macroShortDescription = "This macro checks Fiji installation and prints paths.";
macroDescription = "This macro prints paths of the Fiji installation to the log window." +
	"<br>Check the log window, save it text file (.txt) and use it for trouble shooting";
macroRelease = "first release 02-09-2015 by Martin Stoeter (stoeter(at)mpi-cbg.de)";
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
print("=====================================================================");
print("Fiji version:\n:" + getVersion());
print("current memory:\n:" + IJ.currentMemory()); 
print("max memory:\n:" + IJ.maxMemory());
print("free memory:\n:" + IJ.freeMemory());
print("path to the plugins directory:\n" + getDirectory("plugins"));
print("path to the macros directory:\n" + getDirectory("macros"));
print("path to the luts directory:\n" + getDirectory("luts"));
print("path to the directory that the active image was loaded from:\n" + getDirectory("image"));
print("path to the ImageJ directory:\n" + getDirectory("imagej"));
print("path to the directory that ImageJ was launched from:\n" + getDirectory("startup"));
print("path to users home directory:\n" + getDirectory("home"));
print("path to the temporary directory:\n" + getDirectory("temp"));
print("separator in paths:\n" +File.separator);
print("=====================================================================");
