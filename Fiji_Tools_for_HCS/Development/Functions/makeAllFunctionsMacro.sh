#this script concatenates all .ijm files and stores its content in a new file called Macro_Show_Help_And_Functions.ijm
#set variables
functionHeaderFile=showHelpFunctionHeader.ijm
macroFile=../Macro_Show_Help_And_Functions.ijm

#check if file exists and rename it
if [ -s $macroFile ]
  then
    echo "Macro file $macroFile exists!"
    echo "File was renamed with current date and time tag and new file will be created..."
    mv $macroFile ${macroFile%.*}_$(date +"%Y-%m-%d_%H-%M-%S").ijm
fi

#first write function header file to macro file
echo ""
echo "First file/function in macro is $functionHeaderFile"
cat $functionHeaderFile >> $macroFile

#now concatenate all other function files .ijm
echo "Function files are added..."
for functionFile in *.ijm 
do
  if [ $functionHeaderFile != $functionFile ]
  then
     echo "adding file  $functionFile"
     echo -e "\n" >> $macroFile
     cat $functionFile >> $macroFile
  fi
done
