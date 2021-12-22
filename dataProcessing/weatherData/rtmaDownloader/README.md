# RTMA Downloaders

These scripts download RTMA data from various sources.

![rtmaExample](http://docwatson.ai/wp-content/uploads/2021/12/rtmaExample.png)

`ndgdDownloader.py` downloads from the NCEI National Digital Guidance Database.  But recently the quality and organization of this archive has suffered such that this script is best at retrieving data from 2011 to 2019.  RTMA data is also hosted by several cloud services, so there are better alternatives for more recent data.

`eeRTMAdownloader.py` downloads the RTMA data from Google Earth Engine.  Google maintains a very consistent database of RTMA data there, but precipitation is not included.  You'll need to authenticated, and depending on your use-case, you could violate their terms of service.  Also, it should be noted that projection for the RTMA data is incorrect on Google Earth Engine.  To see what I'm talking about in your favorite GIS software load up temperature data for a summer afternoon and a map of the US.  Zoom in on Cape Cod: you'll see a Cape Cod shaped ghost of high temps floating over the ocean.  This can be corrected with after downloading by resetting the CRS to the correct one (which is in the NDGD data). 
