//function gets all folders from a folder
//example: myFolderList = getFolderList("/home/myFolder/", true);
function getFolderList(inputPathFunction, displayList) {
fileListFunction = getFileList(inputPathFunction);  //read file list
Array.sort(fileListFunction);
returnedFileList = newArray(0);     //this list stores all found files and is returned at the end of the function
for (i=0; i < fileListFunction.length; i++) {
	if ((File.separator == "\\") && (endsWith(fileListFunction[i], "/"))) fileListFunction[i] = replace(fileListFunction[i],"/",File.separator); //fix windows/Fiji File.separator bug
	if (endsWith(fileList[i], File.separator))  returnedFileList = Array.concat(returnedFileList,fileListFunction[i]);//if it is a folder
	}
print(returnedFileList.length + " folders were found."); 
if (displayList) {Array.show("Found folders",returnedFileList);}	
return returnedFileList;
}