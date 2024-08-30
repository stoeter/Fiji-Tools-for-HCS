// This macro was developed by Martin Stöter from HT-TDS in MPI-CBG (stoeter(at)mpi-cbg.de)
// version 2022-04-19

// set path and stack file name
inputPath = "H:/Armin/220324_005AN_COHOs5/yokogawa/processed/";
stackListFileName = "StackList_Zmax_005AN220324a-COHOs5-_";

// image set dimensions
zPlanes = 1;
channels = 2;

// edit this and change the well, then run macro
well = "B06";

// open image set
run("Stack From List...", "open=" + inputPath +stackListFileName + well + "_F000.txt use");

// make hyper stack from stack
frames = round(nSlices / zPlanes / channels);
print(nSlices, zPlanes, channels, frames);
//run("Stack to Hyperstack...", "order=xyczt(default) channels=" + channels + " slices=" + zPlanes + " frames=" + frames + " display=Grayscale");
run("Stack to Hyperstack...", "order=xyczt(default) channels=" + channels + " slices=" + zPlanes + " frames=" + frames + " display=Composite");

// setting contrast
setSlice(1);
run("Green");
setMinAndMax(25, 400);
//run("Enhance Contrast", "saturated=0.35");
setSlice(2);
run("Red");
setMinAndMax(25, 2500);
//run("Enhance Contrast", "saturated=0.35");
//setSlice(3);
//run("Enhance Contrast", "saturated=0.35");
//run("Grays");


