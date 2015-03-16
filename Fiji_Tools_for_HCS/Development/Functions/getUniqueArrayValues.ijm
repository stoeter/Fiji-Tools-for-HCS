//function returnes the unique values of an array in alphabetical order
//example: myUniqueValues = getUniqueArrayValues(myList, true);
function getUniqueArrayValues(inputArray, displayList) {
outputArray = newArray(inputArray[0]);		//outputArray stores unique values, here initioalitaion with first element of inputArray 
for (i = 1; i < inputArray.length; i++) {
	j = 0;									//counter for outputArray
	valueUnique = true;						//as long as value was not found in array of unique values
	while (valueUnique && (outputArray.length > j)) {   //as long as value was not found in array of unique values and end of array is not reached
		if(outputArray[j] == inputArray[i]) {
			valueUnique = false;			//if value was found in array of unique values stop while loop
			} else {
			j++;
			}
		}  //end while
	if (valueUnique) outputArray = Array.concat(outputArray,inputArray[i]);  //if value was not found in array of unique values add it to the end of the array of unique values
	}
print(outputArray.length + " unique values found."); 
Array.sort(outputArray);
if (displayList) {Array.show("List of " + outputArray.length + " unique values", outputArray);}	
return outputArray;
}