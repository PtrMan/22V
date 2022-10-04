// prototype of extremely simple probabilistic vision thingy
//
// run with
//    haxe PROTOVisionBayes0.hx --main PROTOVisionBayes0 --jvm outPROTOVisionBayes0.jar && java -jar ./outPROTOVisionBayes0.jar
//
// keywords: probabilistic
// keywords: probability theory
// keywords: vision
// keywords: vision system
// keywords: perception channel
// keywords: prototype


import ImageOperators;
import Map2dRgb;
import Map2dFloat;
import ColorFilter.ColorFilter2CalcDiff;
import ColorFilter.ColorFilter1ConvToGrayscale;
import Map2dRgbDraw;

class PROTOVisionBayes0 {
    public static function main() {
        
        
        var uut: VisionProbabilisticMotion0 = new VisionProbabilisticMotion0();
        {
            var imageSize: {w:Int, h:Int} = {w:80, h:60};
            uut.init(imageSize); 
        }       


        //# inference to a difference of images
        {
            var imgTminusOne: Map2dRgb = new Map2dRgb(uut.imageSize.w, uut.imageSize.h);
            var imgTzero: Map2dRgb = new Map2dRgb(uut.imageSize.w, uut.imageSize.h);

            //& draw test shapes to both images for training
            //& * we draw boxes which moved
            Map2dRgbDraw.drawBox(imgTminusOne, (30+0)-3, 45-3, (30+0)+3, 45+3, new Rgb(1.0, 0.0, 0.0));
            Map2dRgbDraw.drawBox(imgTzero    , (30+2)-3, 45-3, (30+2)+3, 45+3, new Rgb(1.0, 0.0, 0.0));            

            uut.imgTminusOne = imgTminusOne;
            uut.imgTzero = imgTzero;

            uut.doWork();
        }
    }
}

//& probabilistic motion clustering
class VisionProbabilisticMotion0 {
    public var imgTminusOne: Map2dRgb;
    public var imgTzero: Map2dRgb;

    // settings
    public var patchSize: {w:Int, h:Int} = {w:16, h:16};

    public var imageSize: {w:Int, h:Int} = {w:80, h:60};

    //& visual combinations of ops
    public var visualOpSequences = [];

    //& probability distribution of all differences for each sequence
    public var visualOpSequences_dists: Array<Array<Float>> = [];


    public var proposals: Array<RectInt>; //& result proposals


    //& debugging
    public var dbgFrameNumber: Int = 0; //& frame number for debugging


    public function new() {}

    //& initialize
    public function init(imageSize: {w:Int, h:Int}) {
        this.imageSize = imageSize;

        imgTminusOne = new Map2dRgb(imageSize.w, imageSize.h);
        imgTzero = new Map2dRgb(imageSize.w, imageSize.h);





        


        

        // populate with sequences of operations
        for(diffY in -3...3+1) {
            for(diffX in -3...3+1) {
                var opSequence = [{type:"move", x:diffX, y:diffY}];
                visualOpSequences.push(opSequence);
            }
        }


        

        // loop to compute the distribution for every sequence of image operations, like move or rotate, etc.
        for(ivisualOpSequencesIdx in 0...visualOpSequences.length) {
            var iVisualOpSequence = visualOpSequences[ivisualOpSequencesIdx];

            var imgTminusOne: Map2dRgb = new Map2dRgb(imageSize.w, imageSize.h);
            var imgTzero: Map2dRgb = new Map2dRgb(imageSize.w, imageSize.h);
    
            //& draw test shapes to both images for training
            //& * we draw boxes which moved
            Map2dRgbDraw.drawBox(imgTminusOne, (30+0)                     -3, 45-3                         , (30+0                     )+3, 45+3                         , new Rgb(1.0, 0.0, 0.0));
            Map2dRgbDraw.drawBox(imgTzero    , (30+iVisualOpSequence[0].x)-3, (45+iVisualOpSequence[0].y)-3, (30+iVisualOpSequence[0].x)+3, (45+iVisualOpSequence[0].y)+3, new Rgb(1.0, 0.0, 0.0));
            
    
            var centerTminusOneCenter: {x:Int, y:Int} = {x:30, y:45};
            var centerTzeroCenter: {x:Int, y:Int} = {x:30, y:45};
    
            // map of results (is a map in the sense of a mathematical map)
            //# remember error in map which describes the origins of the sample and maps to the error
            var resultMap: Array<{centerTminusOne: {x:Int, y:Int}, centerTzero: {x:Int, y:Int}, mse:Float}> = [];
    
            // pick a center for image of T-1
            var centerTminusOne: {x:Int, y:Int} = centerTminusOneCenter;
    
            trace('start calculating mse\'s');
            for(diffY in -3...3+1) {
                for(diffX in -3...3+1) {
                    
    
                    var centerTzero: {x:Int, y:Int} = {x:centerTzeroCenter.x + diffX, y:centerTzeroCenter.y + diffY};
    
                    var mse: Float = ImageUtils3.calcMseForSamplePositions(imgTminusOne, centerTminusOne, imgTzero, centerTzero,  patchSize);
                    //trace('mse $mse'); //DBG
                    
                    resultMap.push({centerTminusOne:centerTminusOne, centerTzero:centerTzero, mse:mse}); // remember
                }            
            }
            trace('...finished calculating mse\'s');
    
    
            //# pick best winner
            var winnerIdx:Int = 0;
            var winnerVal:Float = resultMap[0].mse;
    
            for(iidx in 0...resultMap.length) {
                var iv = resultMap[iidx].mse;
                if(iv < winnerVal) {
                    winnerIdx = iidx;
                    winnerVal = iv;
                }
            }
    
            //# give positive evidence to winner in probability distribution
    
    
    
    
    
    
    
    
    
    
            // probability distribution
            // P(so| inmotion(R,1), OPmov(R,2) )
            // where so stands for "same observation" - that is the same observation when a cursor inside image t-1 is moved to image t-0
            var probDist: Array<Float> = [];
            for(i in 0...resultMap.length) {
                probDist.push(1.0);
            }
    
            
    
            probDist = ProbUtils.probDistNormalize(probDist);
    
            var lr: Float = 0.998; //& learning rate
    
            // we reward the right choice to move the cursor based on the motion variables expressed by the conditionals  over multiple actions and multiple frames
            for(iFrame in 0...30) {
                var idx = winnerIdx;
                probDist[idx] = probDist[idx] * (1.0 - lr) + 1.0 * lr; // reward right choice
                probDist = ProbUtils.probDistNormalize(probDist); //& we need to normalize again
            }
    
            /*
            for(iFrame in 0...15) {
                var idx=0;
                probDist[idx] = probDist[idx] * (1.0 - lr) + 1.0 * lr; // reward right choice
                probDist = probDistNormalize(probDist); //& we need to normalize again
            }
            */
    
            Sys.println(probDist); //& dump for human to see magic

            //# store to distribution associated with the operationsequence
            visualOpSequences_dists.push(probDist); // TODO
        }

    }
    
    //& do actual work with the frame
    public function doWork() {
        //& compute the most probably motion vector
        //& /return 
        function calcMotion(centerTzeroCenter: {x:Int, y:Int}): Array<{type: String, x:Int, y:Int}> {
            // map of results (is a map in the sense of a mathematical map)
            //# remember error in map which describes the origins of the sample and maps to the error
            var resultMap: Array<{centerTminusOne: {x:Int, y:Int}, centerTzero: {x:Int, y:Int}, mse:Float}> = [];
    
            // pick a center for image of T-1
            var centerTminusOne: {x:Int, y:Int} = centerTzeroCenter;
    
            //trace('start calculating mse\'s');//DBG
            for(diffY in -3...3+1) {
                for(diffX in -3...3+1) {
                    
    
                    var centerTzero: {x:Int, y:Int} = {x:centerTzeroCenter.x + diffX, y:centerTzeroCenter.y + diffY};
    
                    var mse: Float = ImageUtils3.calcMseForSamplePositions(imgTminusOne, centerTminusOne, imgTzero, centerTzero,  patchSize);
                    //trace('mse $mse'); //DBG
                    
                    resultMap.push({centerTminusOne:centerTminusOne, centerTzero:centerTzero, mse:mse}); // remember
                }
            }
            //trace('...finished calculating mse\'s');//DBG
    
    
            //# pick best winner
            var winnerDistIdx:Int = 0; //& index in the distribution of the winner
            {
                var winnerDistVal:Float = resultMap[0].mse;
    
                for(iidx in 0...resultMap.length) {
                    var iv = resultMap[iidx].mse;
                    if(iv < winnerDistVal) {
                        winnerDistIdx = iidx;
                        winnerDistVal = iv;
                    }
                }
            }

            //trace('DBG winnerDistIdx=$winnerDistIdx'); // DBG


            //# compute the motion sequence which has the highest probability
            var winnerProb:Float = 0.0;
            var winnervisualOpSequences = visualOpSequences[0];
            for(iidx in 0...visualOpSequences.length) {
                var iDist: Array<Float> = visualOpSequences_dists[iidx]; // fetch distribution of the iterated visual sequence
                var selProb:Float = iDist[winnerDistIdx]; // pull out the probability of this distribution by the motion candidate with the lowest MSE
                if (selProb > winnerProb) {
                    winnerProb = selProb;
                    winnervisualOpSequences = visualOpSequences[iidx];
                }
            }
            //& now we got the winner of the most likely motion sequence which explains the change in "winnervisualOpSequences" with the probability "winnerProb"

            //trace('winner prob=${winnerProb}');//DBG
            //trace('winner motion seq=${winnervisualOpSequences}');//DBG

            return winnervisualOpSequences;
        }


        trace('start computing of motion vectors of frame...');
        trace('   imgSize=<${imgTzero.w} ${imgTzero.h}>');

        var motionCommandPerPixelArr = []; // array of pixels, contains the motion information per pixel as motion commands

        for (isampledY in 0...imgTzero.h) {
            //& save resources
            if(isampledY % 2 != 0) {
                continue;
            }

            for (iSampledX in 0...imgTzero.w) {
                //& save resources
                if(iSampledX % 2 != 0) {
                    continue;
                }

                {
                    var motionSeq: Array<{type: String, x:Int, y:Int}> = calcMotion({x: iSampledX, y: isampledY});

                    //& store the motion seq for this pixel
                    motionCommandPerPixelArr.push(motionSeq);
                    
                }
            }
        }

        trace('... done');

        //* dump debug image of motion information to file
        var imgDbgVec: Map2dRgb = new Map2dRgb(Std.int(imageSize.w/2), Std.int(imageSize.h/2)); // image for debugging vector

        var iidx3: Int = 0;
        for(iy in 0...Std.int(imgTzero.h/2)) {
            for(ix in 0...Std.int(imgTzero.w/2)) {
                var sel = motionCommandPerPixelArr[iidx3];
                var vx: Int = sel[0].x; // velocity x
                var vy: Int = sel[0].y; // velocity y
                
                var r:Float = (vx*1.0)/3;
                var g:Float = (vy*1.0)/3;
                //trace('$r $g'); //DBG

                imgDbgVec.writeAtSafe(iy,ix,new Rgb(r,g,0.0));
                iidx3++;
            }
        }



        {
            //& debug motion field
            trace('motion field DBG:');
            for(iy in 0...imgDbgVec.h) {
                var line: String = "";
                
                for(ix in 0...imgDbgVec.w) {
                    var valMotion: Rgb = imgDbgVec.readAtSafe(iy,ix); // read motion vector of motion field

                    //& very simple debugging of field to get started

                    var c:String = ".";
                    if (valMotion.r > 0.0) {
                        c = ">";
                    }
                    if (valMotion.r < 0.0) {
                        c = "<";
                    }

                    if (valMotion.g > 0.0) {
                        c = "V";
                    }
                    if (valMotion.g < 0.0) {
                        c = "^";
                    }
                    
                    line += c;
                }
                trace(line);
            }
        }

        if (true) { //& visual debugging of motion field
            var imgMotionfieldDbgVisu: Map2dRgb = new Map2dRgb(Std.int(imageSize.w/2), Std.int(imageSize.h/2));
            for (iy in 0...imgDbgVec.h) {
                for (ix in 0...imgDbgVec.w) {
                    var valColor: Rgb = imgDbgVec.readAtUnsafe(iy,ix);
                    var valR: Float = (valColor.r + 1.0) * 0.5;
                    var valG: Float = (valColor.g + 1.0) * 0.5;
                    imgMotionfieldDbgVisu.writeAtUnsafe(iy,ix, new Rgb(valR,valG,0.0));
                }
            }

            if(true) PpmExporter.export(imgMotionfieldDbgVisu, 'dbgOut_motionfield0_${dbgFrameNumber}.ppm');
        }

        //throw "DBG5";

        //* compute grouping of motion
        trace('compute grouping ...');
        var groupMotionThreshold = ((1.0/3.0) * 2.0)+0.01; //0.5; // relative pixel motion
        var groupIdMap: Map2dInt = ImageGrouping2dMap.group(imgDbgVec, groupMotionThreshold);
        trace('...done');

        //* debug grouping
        { //& debug grouping to console
            trace('group img DBG:');
            DbgGroupingMap.dbgGrouping(groupIdMap);
        }

        { //& debug grouping as image using size dependent colors to see the groups in a video
            // lowpriority todo
        }

        //* cluster
        proposals = ConvClassmapToGroups.conv(groupIdMap);

        //* filter clusters so that clusters with to few pixels don't get considered at all
        proposals = proposals.filter(iv -> iv.calcArea() > 1);

        //* more filtering
        //& remove proposal(s) which span the whole screen, this is probably the "background"
        proposals = proposals.filter(iv -> !(iv.minx == 0 && iv.miny == 0 && iv.maxx == (groupIdMap.w-1) && iv.maxy == (groupIdMap.h-1)));

        //& debug proposals
        {
            trace('');
            trace('');
            trace('proposals:');
            for(iv in proposals) {
                trace('<${iv.minx} ${iv.miny} ${iv.maxx} ${iv.maxy}>');
            }
        }
    }
}

//& probability utilities
class ProbUtils {
    //& function to normalize a probability distribution
    public static function probDistNormalize(dist: Array<Float>): Array<Float> {
        var sum:Float = 0.0;
        for(iv in dist) {
            sum+=iv;
        }
        var acc:Array<Float> = [];
        for(iv in dist) {
            acc.push(iv/sum);
        }
        return acc;
    }
}

class ImageUtils3 {
    
    //& compute mse of difference of the two patches from image before and current image
    public static function calcMseForSamplePositions(imgTminusOne: Map2dRgb, centerTminusOne: {x:Int, y:Int}, imgTzero: Map2dRgb, centerTzero: {x:Int, y:Int},  patchSize: {w:Int, h:Int}): Float {
        var patchTminusOne: Map2dRgb = ImageOperators.subImg(imgTminusOne, centerTminusOne.x - Std.int(patchSize.w/2), centerTminusOne.y - Std.int(patchSize.h/2), patchSize.w, patchSize.h);
        var patchTzero: Map2dRgb = ImageOperators.subImg(imgTzero, centerTzero.x -  Std.int(patchSize.w/2), centerTzero.y - Std.int(patchSize.h/2), patchSize.w, patchSize.h);

        //# compute difference
        var patchDiffRgb: Map2dRgb = ImageOperators.applyFilter2(patchTminusOne, patchTzero, new ColorFilter2CalcDiff());
        
        //# compute error
        var patchDIffGrayA: Map2dRgb = ImageOperators.applyFilter1(patchDiffRgb, new ColorFilter1ConvToGrayscale());
        var patchDIffGray: Map2dFloat = ImageOperators.extractChannelRed(patchDIffGrayA);
        var mse: Float = ImageOperators.calcMse(patchDIffGray);
        return mse;
    }
}





//& image grouping of a 2d map, works very similar to class "ImageGrouping"
class ImageGrouping2dMap {
    // /param threshold of motion difference, for starting 0.01
    public static function group(img: Map2dRgb, threshold: Float): Map2dInt {
        var idMap0: Map2dInt = new Map2dInt(img.w, img.h); // map used to store the regions of the pixels

        {
            var regionId = 2; // region id counter, used to keep track of 
            // assign each pixel a id
            for(iy in 0...img.h) {
                for(ix in 0...img.w) {
                    //if(!img.readAtSafe(iy,ix)) {
                    //    continue; // we don't need to group this if there is no pixel
                    //}

                    var valThisU = img.readAtSafe(iy-1, ix   );
                    var valThisL = img.readAtSafe(iy  , ix-1 );
                    var valThis  = img.readAtSafe(iy  , ix   );


                    var diff0: Rgb = Rgb.sub(valThis, valThisL);
                    var diff0Metric: Float = Math.abs(diff0.r*diff0.r + diff0.g*diff0.g);

                    var diff1: Rgb = Rgb.sub(valThis, valThisU);
                    var diff1Metric: Float = Math.abs(diff1.r*diff1.r + diff1.g*diff1.g);


                    /*
                    // commented because hack is not necessary?
                    if (
                        (Math.abs(valThisU.r) < 0.001 && Math.abs(valThisU.g) < 0.001) ||
                        (Math.abs(valThisL.r) < 0.001 && Math.abs(valThisL.g) < 0.001)
                    ) { //& special handling for no motion in unnatural images for testing, evaluation etc., ignore, is a dirty HACK
                        // null id
                        idMap0.writeAtSafe(iy,ix,1); //& we write a 1 because it stands for "no movement"
                    }
                    else 
                    //*/
                    {
                        if (diff0Metric + diff1Metric < threshold) { // is the difference greater than some threshold?
                            // assign same id as from up and left
                            var idL: Int = idMap0.readAtSafe(iy  , ix-1);
                            var idU: Int = idMap0.readAtSafe(iy-1, ix  );
                            var idFin: Int = MathUtils2.minInt(idL,idU); // take min() to compute ONE id to assign, we can't take max() because id's always 'slide' up
                            idMap0.writeAtSafe(iy,ix,idFin);
                        }
                        else {
                            // add new group
                            idMap0.writeAtSafe(iy,ix,regionId);
                            regionId++;
                        }
    
                        //var val0: Int = idMap0.readAtSafe(iy,ix); // DBG
                        //trace('$val0'); // DBG
                    }
                }

                //trace('--'); // DBG
            }
        }


        // HACK for debugging
        /*
        {
            idMap0 = new Map2dInt(40, 4);

            for(idx in 0...40) {
                var arr = [0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  200,  201,  202,  203,  204,  205,  193,  206,  207,  196,  196,  208,  209,  210,  0,  0,  0,  0,  0,  0 , 0 , 0 , 0 , 0 , 0 ,];
                idMap0.writeAtSafe(0, idx, arr[idx]);
            }

            for(idx in 0...40) {
                var arr = [ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  211,  212,  213,  204,  204,  193,  193,  214,  196,  196,  196,  196,  215,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ];
                idMap0.writeAtSafe(1, idx, arr[idx]);
            }

            for(idx in 0...40) {
                var arr = [0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ,216 , 212,  217,  218 , 219,  220,  221,  214 , 196 , 196 , 196 , 196 , 222,  0,  0,  0,  0,  0 , 0 , 0 , 0 , 0 , 0,  0  ];
                idMap0.writeAtSafe(2, idx, arr[idx]);
            }

            for(idx in 0...40) {
                var arr = [ 0 , 0 , 0  ,0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 223,  224,  225,  226,  227,  220,  228,  214,  196,  196,  196,  196,  229,  0,  0,  0,  0,  0,  0 , 0 , 0  ,0 , 0 , 0 ];
                idMap0.writeAtSafe(3, idx, arr[idx]);
            } 
        }

        {
            idMap0 = new Map2dInt(3, 3);

            for(idx in 0...3) {
                var arr = [206 , 207,  196];
                idMap0.writeAtSafe(0, idx, arr[idx]);
            }

            for(idx in 0...3) {
                var arr = [193 , 214 , 196];
                idMap0.writeAtSafe(1, idx, arr[idx]);
            }

            for(idx in 0...3) {
                var arr = [221,  214,  196 ];
                idMap0.writeAtSafe(2, idx, arr[idx]);
            }
            
        }
        */


        // TODO< refactor this into common functionality with "ImageGrouping" ! >


        if (true) {
            trace('group img before reassign');
            DbgGroupingMap.dbgGrouping(idMap0);
        }

        // group id's to clusters of regions
        var remapIds:Map<Int, Int> = new Map<Int, Int>();
        var mapCnt = 1;

        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                //if(!img.readAtSafe(iy,ix)) {
                //    continue; // we don't need to group this if there is no pixel
                //}

                var id = idMap0.readAtSafe(iy,ix);
                var mappedToId = remapIds.get(id);
                if (mappedToId == null) { // is it not mapped to an id?
                    
                    // search adjacent id
                    var lVal: Int = idMap0.readAtSafe(iy-1,ix  );
                    var uVal: Int = idMap0.readAtSafe(iy  ,ix-1);

                    //var lMappedToId = remapIds.get(lVal);
                    //var uMappedToId = remapIds.get(uVal);

                    var neightborSuggestedId: Int = MathUtils2.maxInt(lVal,uVal); //& suggested id is the maximum

                    if (neightborSuggestedId == 0) { // is no ID assigned?
                        // then assign new one
                        remapIds.set(id, mapCnt);
                        mapCnt++;
                    }
                    else {
                        //BUGGY remapIds.set(neightborSuggestedId, neightborSuggestedId); // add the mapping

                        if (neightborSuggestedId != id) {
                            remapIds.set(id, mapCnt);
                            mapCnt++;
                        }
                    }
                }
                else { // is it mapped to an id?
                    // do nothing
                }
            }
        }

        if (true) {
            // reassign id's by clusters
            for(iy in 0...img.h) {
                for(ix in 0...img.w) {
                    //if(!img.readAtSafe(iy,ix)) {
                    //    continue; // we don't need to group this if there is no pixel
                    //}

                    var id = idMap0.readAtSafe(iy,ix);
                    var mappedToId = remapIds.get(id);
                    if (mappedToId == null) { //& is the id unknown? must not happen!
                        trace('ERR: id $id is unknown!');
                    }
                    idMap0.writeAtSafe(iy,ix, mappedToId);
                }
            }
        }

        if (true) {
            trace('group img after reassign');
            DbgGroupingMap.dbgGrouping(idMap0);
        }


        ///throw "DBG3";

        // return result
        return idMap0;
    }
}


//& used for debugging grouping map
class DbgGroupingMap {
    public static function dbgGrouping(map: Map2dInt) {
        for(iy in 0...map.h) {
            var l: String = "";
            for(ix in 0...map.w) {
                var iId: Int = map.readAtSafe(iy,ix);
                l += '$iId  ';
            }
            trace(l);
        }
    }
}
