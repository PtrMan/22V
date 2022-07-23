import Map2dRgb;

// reader for PPM image file format
class PpmReader {
    public static function readPpm(path: String): Map2dRgb {
        var filecontent: String = sys.io.File.getContent(path);
        
        var lines: Array<String> = filecontent.split("\n");

        var iLineCnt: Int = 0; // line counter
        var datCnt: Int = 0; // counter for current data, used to decide if pixel is red/green/blue

        var imgSizeX: Int = -1;
        var imgSizeY: Int = -1;

        var valR: Float = 0.0;
        var valG: Float = 0.0;
        var valB: Float = 0.0;

        var out: Map2dRgb = null;

        var outX: Int = 0;
        var outY: Int = 0;

        for(iLine in lines) {
            if (iLine.length == 0) {
                continue;
            }
            if (iLine.charAt(0) == '#') { // is comment?
                continue; // skip
            }

            if (iLineCnt == 0) {
                // skip first line;
            }
            else if(iLineCnt == 1) {
                // second line contains size of image
                var splitted = iLine.split(" ");
                imgSizeX = Std.parseInt(splitted[0]);
                imgSizeY = Std.parseInt(splitted[1]);

                out = new Map2dRgb(imgSizeX, imgSizeY);
            }
            else if(iLineCnt == 2) {
                // third line contains number of steps of value, we assume 255, skip!
            }
            else {
                var splitted = iLine.split(" ");
                for (iSplitted in splitted) {
                    if (iSplitted == "") { // this is necessary for some exporters
                        continue; // skip
                    }

                    var valInt: Int = Std.parseInt(iSplitted);
                    var valF: Float = valInt;
                    valF /= 255.0; // normalize

                    var idx3: Int = datCnt % 3;
                    if (idx3 == 0) {
                        valR = valF;
                    }
                    else if (idx3 == 1) {
                        valG = valF;
                    }
                    else if (idx3 == 2) {
                        valB = valF;

                        // store
                        //var outCnt: Int = Std.int(datCnt / 3); // used to compute pixel position in output
                        //var outX: Int = outCnt % imgSizeX;
                        //var outY: Int = Std.int(outCnt / imgSizeX);

                        out.writeAtSafe(outY, outX,  new Rgb(valR, valG, valB)); // write out

                        // andvance output pixel position
                        outX++;
                        if (outX == imgSizeX) {
                            outX=0;
                            outY++;
                        }
                    }

                    datCnt++;
                }
            }

            iLineCnt++;
        }

        return out;
    }
}
