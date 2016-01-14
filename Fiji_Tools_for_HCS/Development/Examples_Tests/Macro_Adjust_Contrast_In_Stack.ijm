getDimensions(width, height, channels, slices, frames);
for(currentSlice = 1; currentSlice <= slices; currentSlice++) {
	setSlice(currentSlice);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT", "slice");
	}
saveAs("Tiff", "");	
