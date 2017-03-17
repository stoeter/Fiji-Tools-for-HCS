//function returnes the unique acquisition numbers of an array of CV7000 files
//example: myUniqueAcquisitions = getUniqueAcquisitionListCV7000(myList, true);
function getUniqueAcquisitionListCV7000(inputArray, displayList) {
if(inputArray.length < 1) {
	print("No wells acquisition number found!");
	return newArray(0);
	}
currentAcquisition = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")+13,lastIndexOf(inputArray[0],"_T00")+16);   //first acquisition found
returnedAcquisitionList = Array.concat(currentAcquisition);     //this list stores all unique cquisitions found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned cquisition list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedAcquisitionList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentAcquisition = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")+13,lastIndexOf(inputArray[i],"_T00")+16);
		if(returnedAcquisitionList[j] == currentAcquisition) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedAcquisitionList = Array.concat(returnedAcquisitionList, currentAcquisition);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedAcquisitionList.length + " acquisition numbers found."); 
Array.sort(returnedAcquisitionList);
if (displayList) {Array.show("List of " + returnedAcquisitionList.length + " unique acquisition numbers", returnedAcquisitionList);}	
return returnedAcquisitionList;
}