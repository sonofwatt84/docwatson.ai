# Buffer Sampler

This script samples data from the area near a spatial line, like a road or power line.  It draws a buffer around that line, and then samples the raster data found withing the buffer, generating summary statistics.  The script here is designed to sample a categorical raster from around roads for each county in the USA.

![bufferPlot](http://docwatson.ai/wp-content/uploads/2021/12/circuitMap1-small.png)

This type of processing has applications in merging high-res datasets of land cover, elevation, etc to the proximity of particular infrastructural networks. 
