//function returnes the unique well files (all fields of all wells, e.g. G10_T0001F001) of an array of CV7000 files
//example: myUniqueWellFileds = getUniqueWellFieldListCV7000(myList, true);
function getUniqueWellFieldListCV7000(inputArray, displayList) {
currentWellField = substring(inputArray[0],lastIndexOf(inputArray[0],"_T00")-3,lastIndexOf(inputArray[0],"_T00")+10);   //first well field found
returnedWellFieldList = newArray(currentWellField);     //this list stores all unique wells fields found and is returned at the end of the function
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for returned well field list
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (returnedWellFieldList.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		currentWellField = substring(inputArray[i],lastIndexOf(inputArray[i],"_T00")-3,lastIndexOf(inputArray[i],"_T00")+10);
		if(returnedWellFieldList[j] == currentWellField) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) returnedWellFieldList = Array.concat(returnedWellFieldList, currentWellField);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(returnedWellFieldList.length + " wells fiels found."); 
Array.sort(returnedWellFieldList);
if (displayList) {Array.show("List of " + returnedWellFieldList.length + " unique well fields", returnedWellFieldList);}	
return returnedWellFieldList;
}