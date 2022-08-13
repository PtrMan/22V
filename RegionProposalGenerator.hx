import Map2dRgb;
import Map2dBool;
import RectInt;


import ImageGrouping;

// used to generate propasal regions by difference between two (low res) frames
class RegionProposalGenerator {
    // /param colorDistThreshold: Float = 3.0; // threshold for a disttance to be recognized as a part of a region
    public static function calcRegions(imgA: Map2dRgb, imgB: Map2dRgb, colorDistThreshold: Float): Array<{rect:RectInt,id:Int}> {
        var mapBool: Map2dBool = new Map2dBool(imgA.w, imgA.h);
        
        for(iy in 0...imgA.h) {
            for(ix in 0...imgA.w) {
                // calc diffs
                var colorA: Map2dRgb.Rgb = imgA.readAtUnsafe(iy,ix);
                var colorB: Map2dRgb.Rgb = imgB.readAtUnsafe(iy,ix);
                var diffR: Float = colorA.r - colorB.r;
                var diffG: Float = colorA.g - colorB.g;
                var diffB: Float = colorA.b - colorB.b;
                
                // calc manhattan distance of color diff
                var dist: Float = Math.abs(diffR) + Math.abs(diffG) + Math.abs(diffB);

                var boolVal: Bool = dist >= colorDistThreshold;

                mapBool.writeAtUnsafe(iy,ix,boolVal);
            }
        }

        return cluster(mapBool);
    }

    public static function cluster(mapBool:Map2dBool): Array<{rect:RectInt,id:Int}> {
        // do actual clustering
        var groupingMap: Map2dInt = ImageGrouping.group(mapBool);

        
        // * build resulting "proposals"
        var rects: Map<Int, RectInt> = new Map<Int, RectInt>();

        for(iy in 0...groupingMap.h) {
            for(ix in 0...groupingMap.w) {
                var id:Int = groupingMap.readAtSafe(iy,ix);
                if (id == 0) {
                    continue;
                }
                
                var rect:RectInt = rects.get(id);
                if (rect == null) { // does it already exist?
                    rects.set(id, new RectInt(ix,iy,ix,iy));
                }
                else {
                    rect.include(ix,iy);
                    rects.set(id, rect);
                }
            }
        }


        // translate rects map to array with rectangles
        var outArr: Array<{rect:RectInt,id:Int}> = [];
        for (iKeyValue in rects.keyValueIterator()) {
            outArr.push({rect:iKeyValue.value,id:iKeyValue.key});
        }

        return outArr;
    }
}

/* commented because it is overkill
class RegionProposalGeneratorCtx {
    public var colorDistThreshold: Float = 3.0; // threshold for a disttance to be recognized as a part of a region

    public function new() {}
}
*/