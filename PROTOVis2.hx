// protoype for vision with ART

// file history:
// 15.07.2022: initial version

import sys.thread.FixedThreadPool;
//import sys.thread.Mutex;
import sys.thread.Lock;
import sys.io.Process;

import Vec2;
import ImageOperators;
import BRealvectorUtils;
import BBitvectorUtils;
import Rng0;
import ProtoobjectClassifier;

import PROTOVisionBayes0;

import GaborKernel;

import MyArt_v1;

import PpmExporter;


import PROTOExternalClassThingy0; // for testing


import ParticleBasedGroupingAlgo;
import CfgParser;


import VXSituationDetector; // for testing if it compiles
import VXSitationClassifier; // for testing if it compiles

import VSaccadeCommonDat;
import VSaccadeUtilities;

import VSaccade2;

class PROTOVis2 {
    

    // initializes
    public static function defaultInit(ctx: Vis2Ctx) {
        accuLock0 = new Lock();
        accuLock0.release();
        
        var prototypeClassifier__VecLen: Int = 300;
        var prototypeClassifier__gridElementsPerDimension: Int = 6;
        var prototypeClassifier__thresholdCreateNewItem: Float = 0.71; // TODO< tune this! >

        ctx.prototypeClassifierCtx = new ProtoobjectClassifierCtx(prototypeClassifier__VecLen, prototypeClassifier__gridElementsPerDimension);
        ctx.prototypeClassifierCtx.thresholdCreateNewPrototype = prototypeClassifier__thresholdCreateNewItem;
        ctx.prototypeClassifierCtx.param__nMaxProtoobjects = 1000; // AIKR setting

        ctx.paramSaccadesNMax = 3000; //2000; // AIKR setting
        ctx.foveaWidthPixels = 20; // AIK setting
        ctx.saccadePositionSimThreshold = 0.88; // TODO< tune this! >

        ctx.artClassifier = new MyArt_v1();

        // TODO< bigger size of image? >
        ctx.artClassifier.vecWidth = (ctx.foveaWidthPixels*ctx.foveaWidthPixels) * ctx.config__conv__nConvolutionOrientations; // NOTE< last multiplication is for number of convolutions used for classification >
        
        
        ctx.artClassifier.a = 7.5; //120.0; //0.1; //7.5; //12.5;     // 12.5; //0.2; //12.5; // 7.5  // more contrast?
        ///ctx.artClassifier.b = 1.01;
        ctx.artClassifier.vigilance = 1.0; // 1.0 // more classes
        


        // new settings - works great by creating lots of classes
        ctx.artClassifier.a = 20.0; //220.5;
        ctx.artClassifier.e = 2.0;
        ctx.artClassifier.vigilance = 0.5;

        

        // tuning 
        ctx.artClassifier.vigilance = 0.99;


        var config__vxSituationDetectorCtx__vecLength = 512;
        ctx.vxSituationDetectorCtx = new VXSituationDetectorContext(config__vxSituationDetectorCtx__vecLength);

        var config__vxSitationClassifierCtx__nEntriesMax = 100;
        ctx.vxSitationClassifierCtx = new VXSitationClassifierCtx(config__vxSitationClassifierCtx__nEntriesMax);


        readCfg(ctx);
        
        ctx.artClassifier.init(ctx.artRng);

        ctx.artCtxs.push(new ArtCtx(ctx.artClassifier));
        ctx.artCtxs.push(new ArtCtx(ctx.artClassifier));
        ctx.artCtxs.push(new ArtCtx(ctx.artClassifier));
        ctx.artCtxs.push(new ArtCtx(ctx.artClassifier));


        // make sure all ids of the point to a valid unique HD-vector
        var rngUsedForUniqueVectors: Rng0 = new CryptoRng0("hd0");
        for (iId in 0...ctx.artClassifier.M) {
            ctx.prototypeClassifierCtx.circuitCtx.idLookupTable.set(iId, BRealvectorUtils.genRandom(ctx.prototypeClassifierCtx.circuitCtx.vecLen, rngUsedForUniqueVectors));
        }




        ctx.img = new Map2dRgb(32,32); // init with dummy image



        ctx.visionProbMotion.init(TODO);
    }

    // read and parse config file
    public static function readCfg(ctx: Vis2Ctx) {
    
        var cfgFileContent: String = sys.io.File.getContent("./vision.default.cfg");
        var cfgValues: Map<String, Invariant> = CfgParser.parse(cfgFileContent);

        ctx.artClassifier.a = InvariantUtils.retReal(cfgValues["art.a"]);
        ctx.artClassifier.b = InvariantUtils.retReal(cfgValues["art.b"]);
        ctx.artClassifier.c = InvariantUtils.retReal(cfgValues["art.c"]);
        ctx.artClassifier.d = InvariantUtils.retReal(cfgValues["art.d"]);
        ctx.artClassifier.e = InvariantUtils.retReal(cfgValues["art.e"]);
        ctx.artClassifier.vigilance = InvariantUtils.retReal(cfgValues["art.vigilance"]);
        ctx.artClassifier.resetAttempts = InvariantUtils.retInt(cfgValues["art.resetAttempts"]);
        ctx.artClassifier.roundsLtm = InvariantUtils.retInt(cfgValues["art.roundsLtm"]);
        ctx.artClassifier.M = InvariantUtils.retInt(cfgValues["art.M"]);
        
        
        ctx.artClassifier.sigma = InvariantUtils.retReal(cfgValues["art.sigma"]);

        ctx.particleBasedGrouping.setting__velScale = InvariantUtils.retReal(cfgValues["particleBasedGrouping.velScale"]);
        ctx.particleBasedGrouping.setting__velNullThreshold = InvariantUtils.retReal(cfgValues["particleBasedGrouping.velNullThreshold"]);
        ctx.particleBasedGrouping.setting__quantizationRanges = InvariantUtils.retInt(cfgValues["particleBasedGrouping.quantizationRanges"]);
    }

    // function to push a new image.
    // it tells the vision system that the image has changed, this triggers further (pre)-processing
    public static function notifyImageUpdated(ctx: Vis2Ctx) {
        if (true) { // do we compute convolutions???
            // compute all necessary convolutions
            var convolutionImages: Array<Map2dRgb> = _helper__calcConv(ctx);

            // store convolution images in context
            ctx.convolutionImages = convolutionImages;
        }
    }

    // implementation of single cycle of processing
    public static function doCycle(ctx: Vis2Ctx) {
        ctx.cycleEpoch++;
        
        if (false) { // DBG level 1
            Sys.print('\n\n\n');
        }

        var timeCycleBegin: Float = Sys.time();

        if (ctx.cycleEpoch % 231 == 0) { // check for condition to do GC
            // force GC
            SaccadeSetUtils.saccadeGc(ctx);
        }

        if (ctx.cycleEpoch % 9481 == 0) {
            ProtoobjectClassifier.gc(ctx.cycleEpoch, ctx.prototypeClassifierCtx);
        }


        // try to extend saccades
        {
            if (ctx.miscRng.genFloat01() < 0.2) { // check probability to generate a continuation of a saccade
                // try to find a saccade for continuation

                var continuationSeedPathLength: Int = 3; // is the length of the saccade path which should get extended

                if (ctx.miscRng.genFloat01() < 0.1) { // probability to try to continue a path of the length of 4
                    continuationSeedPathLength = 4;
                }


                if (ctx.saccadeSetByLength[continuationSeedPathLength].length > 0) {
                    
                    // select random "entry" position in image
                    var foveaCenterLoc: Vec2 = ctx.foveaCenterProposalStrategy.calcNextProposalPos(ctx.foveaCenterRng, {w:ctx.img.w,h:ctx.img.h}); // generate new center position of fovea
                    
                    // classify at the position
                    {
                        var resSingleVertex:  Array<{saccadeVertexIdx:Int,x:Int,y:Int,class_:Int}> = eyeSaccade__exec2([new Vec2(0.0,0.0)], foveaCenterLoc,  ctx, false);
                        
                        var classOfFirstVertex: Int = resSingleVertex[0].class_; // we only care about the class of the first vertex of the 'saccade'

                        // filter saccades by class of first vertex
                        var candidateSaccades3: Array<DecoratedPathWithHdEncoding> = ctx.saccadeSetByLength[continuationSeedPathLength].filter(iv -> iv.payload.pathSaccade.pathItems[0].class_ == classOfFirstVertex); // filter so it's the saccade which starts with the class
                        if (candidateSaccades3.length > 0) {

                            // select random candidate
                            var selIdx: Int = ctx.miscRng.genInt(candidateSaccades3.length);
                            var selSeedSaccade3: DecoratedPathWithHdEncoding = candidateSaccades3[selIdx];

                            // * we need to check out if the selected saccade matches to the situation in the actual image
                            var candidateSaccadePositions: Array<Vec2> = selSeedSaccade3.payload.pathSaccade.pathItems.map(iv -> iv.relRelPos);
                            var candidateSaccadeClasses: Array<Int> = eyeSaccade__exec(candidateSaccadePositions, foveaCenterLoc,  ctx);



                            // * create new EyesaccadePath from the classifications
                            var saccade: EyesaccadePath = new EyesaccadePath();
                            for (iIdx in 0...candidateSaccadePositions.length) {
                                var iRelPosition: Vec2 = candidateSaccadePositions[iIdx];
                                var iClass: Int = candidateSaccadeClasses[iIdx];
                                saccade.pathItems.push(new PathItem(iRelPosition, iClass));
                            }

                            // * cast to SaccadeWithHdEncoding
                            var saccadeWithHdEncoding: PathWithHdEncoding = SaccadeSetUtils.castPathToPathWithHdEncoding(saccade,  ctx);

                            var sim: Null<Float> = VSaccadeUtilities.cmpSaccades(selSeedSaccade3.payload, saccadeWithHdEncoding, 0, 0); // compare candidate to actual saccade which was executed
                            if (sim != null) { // is it similar enough?
                                // * try to extend it
                                // the function also appends the new saccade!
                                var resSaccade: DecoratedPathWithHdEncoding = SaccadeUtils2.saccadeComputeContinuation(selSeedSaccade3.payload, foveaCenterLoc,  ctx);
                            }
                        }
                    }
                }
            }
        }


        { // sample new 3-saccades
            //ctx.eyeSaccadeRng = new CryptoRng0("4243"); // HACK TESTING< force a new rng for the same eye saccade coordinates >
            var candidateSaccadePositions: Array<Vec2> = eyeSaccadePathGen__generateRandomEyeSaccade (3, ctx.img.w, ctx.eyeSaccadeRng);

            // * execute saccade
            var foveaCenterLoc: Vec2 = ctx.foveaCenterProposalStrategy.calcNextProposalPos(ctx.foveaCenterRng, {w:ctx.img.w,h:ctx.img.h}); // generate new center position of fovea
            var candidateSaccadeClasses: Array<Int> = eyeSaccade__exec(candidateSaccadePositions, foveaCenterLoc,  ctx);
            
            if (false) { // DBG
                Sys.println('classes of saccade:');
                for (iClass in candidateSaccadeClasses) {
                    Sys.println('   cls=$iClass');
                }
            }

            // * create new EyesaccadePath from the classifications
            var saccade: EyesaccadePath = new EyesaccadePath();
            for (iIdx in 0...candidateSaccadePositions.length) {
                var iRelPosition: Vec2 = candidateSaccadePositions[iIdx];
                var iClass: Int = candidateSaccadeClasses[iIdx];
                saccade.pathItems.push(new PathItem(iRelPosition, iClass));
            }

            // * cast to SaccadeWithHdEncoding
            var saccadeWithHdEncoding: PathWithHdEncoding = SaccadeSetUtils.castPathToPathWithHdEncoding(saccade,  ctx);

            // * try to find similar existing saccade
            var bestCandidateExistingSaccade: DecoratedPathWithHdEncoding = SaccadeSetUtils.lookupBestSaccadeByPositionAndVertexClass(saccadeWithHdEncoding,  ctx);
            
            var chosenCandidateSaccade: DecoratedPathWithHdEncoding = bestCandidateExistingSaccade; // variable which holds the chosen saccade
            if (bestCandidateExistingSaccade == null) { // was no best matching eye saccade found?
                if (false) { // DBG
                    Sys.println('DBG: add saccade');
                }

                chosenCandidateSaccade = SaccadeSetUtils.appendSaccade(saccadeWithHdEncoding,   ctx);
            }

            chosenCandidateSaccade.cycleEpochLastUse = ctx.cycleEpoch; // we need to update this to know which saccade was used last for GC



            // reward similar candidiates with new algorithm from 11.09.2022
            {
                var selSaccades = ctx.saccadeSetByLength[saccadeWithHdEncoding.pathSaccade.pathItems.length];
                ZZZ.x(saccadeWithHdEncoding, selSaccades, ctx.saccadeRewardCtx);
            }


            // OUTPUT
            ////Sys.println('OUT: saccade.id=${chosenCandidateSaccade.id} pos=<${Std.int(foveaCenterLoc.x)} ${Std.int(foveaCenterLoc.y)}>'); // output to outside system a message that
            
            if (ctx.emitNarsese) {
                Sys.println('OUTN:<{(saccid${chosenCandidateSaccade.id}*(${Std.int(foveaCenterLoc.x/10)}*${Std.int(foveaCenterLoc.y/10)}))} --> perceptSac>. :|:'); // create narsese
            }
        }


        var timeCycleEnd: Float = Sys.time();
        var timeCycle: Float = timeCycleEnd - timeCycleBegin;
        ctx.diagnostics__timeCycleAccu += timeCycle;
        ////trace('diagnostics.time.cycle=${ctx.diagnostics__timeCycleAccu}');
    }

    // must be called when the processing of a frame begins
    public static function startFrame(ctx: Vis2Ctx) {
        if (ctx.frameCounter == 0) {
            // then we need to set the last frame equal to the current frame!
            ctx.imgFrameBefore = ctx.img;
        }
    }

    // must be called when the processing of a frame is done
    public static function endFrame(ctx: Vis2Ctx) {
        ctx.frameCounter++;

        if ((ctx.frameCounter % 600) == 0) {
            VXSituationDetector.forceGc(ctx.vxSituationDetectorCtx);

            VXSitationClassifier.forceGc(ctx.vxSitationClassifierCtx);
        }

        // TODO TODO TODO< set this to true and see what it does with a video
        var enProcessAsStream: Bool = true; // process the input images as a continuos stream?



        // collect stimulus items of sub-frame of image
        // /param center is the absolute position in the frame of the center to collect the level0 classifications from
        function collectStimulusItemsOfSubFrame(center:{x:Int,y:Int}, frameSize: Int): Array<{pos:{x:Int,y:Int},id:Int}> {
            
            // helper to compute if a absolute position is inside the sub-frame
            function isInSubframe(pos: {x:Int,y:Int}) {
                //var frameSize: Int = Std.int(ctx.img.w/5.0); // TODO< add this as a parameter to ctx!!! >
                
                var diffX: Int = pos.x - center.x;
                var diffY: Int = pos.y - center.y;
                
                var absDiffX: Int = MathUtils2.absInt(diffX);
                var absDiffY: Int = MathUtils2.absInt(diffY);

                return absDiffX <= frameSize/2 && absDiffY <= frameSize/2;
            }
            
            var samplesInFrame = ctx.level0SampleContainer.filter(iv -> isInSubframe({x:iv.pos.x,y:iv.pos.y}));
            return samplesInFrame;
        }

        // convert from absolute position to relative position relative to frame
        // IMPLEMENTATION< details need to be syncronized with implementation of collectStimulusItemsOfSubFrame() ! >
        function mapAbsolutePosToRelative(center:{x:Int,y:Int}, v:{pos:{x:Int,y:Int},id:Int}, frameSize: Int): {pos:{x:Float,y:Float},id:Int} {
            //var frameSize: Int = Std.int(ctx.img.w/5.0); // TODO< add this as a parameter to ctx!!! >

            var diffX: Int = v.pos.x - center.x;
            var diffY: Int = v.pos.y - center.y;

            return {pos:{x:diffX / frameSize,y:diffY / frameSize},id:v.id};
        }



        // used to collect the protoObjects for this frame
        var protoObjects: Array<{center:{x:Int,y:Int},protoobj:ProtoobjectClassifierItem}> = [];



        // helper to compute center and extend of "ProposalRegion"
        function calcCenterAndExtendOfProposalRegion(proposalRegion): {center:{x:Int,y:Int}, extend:Int} {
            var centerX: Int = Std.int((proposalRegion.rect.maxx+proposalRegion.rect.minx) / 2.0);
            var centerY: Int = Std.int((proposalRegion.rect.maxy+proposalRegion.rect.miny) / 2.0);

            var extend: Int = proposalRegion.rect.maxx-proposalRegion.rect.minx; // we take the width of the "proposalRegion" as the width and height of the region which we use to classify the proto-object

            return {center:{x:centerX,y:centerY}, extend:extend};
        }


        // helper to add a proposal by classification of a proposal region
        function classifyByCenterAndExtend(centerAndExtend, enRevision: Bool = true): {item:ProtoobjectClassifierItem, similarity:Float} {
            
            var stimulusItemsA: Array<{pos:{x:Int,y:Int},id:Int}> = [];
            var sampledCenter: {x:Int,y:Int} = centerAndExtend.center;
            stimulusItemsA = collectStimulusItemsOfSubFrame(sampledCenter, centerAndExtend.extend);

            // map to relative positions
            var stimulusItems: Array<{pos:{x:Float,y:Float},id:Int}> = stimulusItemsA.map(iv -> mapAbsolutePosToRelative(sampledCenter, iv, centerAndExtend.extend));
            
            // FIXME< this is a hack to remove id's -1 where the ART classifier returned -1, this shouldn't happen and is a bug in ART2 implementation >
            stimulusItems = stimulusItems.filter(iv -> return iv.id != -1);

            // * compute protoobject coresponding with the perceived protoobject at the given position
            var protoobjectAtCenter: {item:ProtoobjectClassifierItem, similarity:Float} = ProtoobjectClassifier.classify(stimulusItems, ctx.cycleEpoch, ctx.prototypeClassifierCtx, enRevision); // classify samples to get level1 classification
            return protoobjectAtCenter;
        }



        // classify by center+extend and append classification result to "protoObjects" array
        function classifyByCenterAndExtendAndAppendProtoobj(centerAndExtend) {
            var protoobjectAtCenter = classifyByCenterAndExtend(centerAndExtend);
            
            // store "protoobjectAtCenter"
            protoObjects.push({center:centerAndExtend.center, protoobj:protoobjectAtCenter.item});
        }



        // * classify protoobjects based on  - difference of pixels of image
        if (enProcessAsStream && ctx.config__typeProtobjectSrc == "diff") {
            
            // downsamples "img" and "imgFrameBefore"
            var downscaledImg: Map2dRgb = ImageOperators.scale(ctx.img, Std.int(ctx.img.w*ctx.config__frameDiff_downsampleFactor));
            var downscaledImgFrameBefore: Map2dRgb = ImageOperators.scale(ctx.imgFrameBefore, Std.int(ctx.img.w*ctx.config__frameDiff_downsampleFactor));

            // * compute proposal regions
            var proposalRegions: Array<{rect:RectInt,id:Int}> = RegionProposalGenerator.calcRegions(downscaledImg, downscaledImgFrameBefore, ctx.config__frameDiff_threshold);

            // * work with proposal regions
            {
                // we use the proposals as regions for classification of protoobjects
                for (iProposalRegion in proposalRegions) {
                    var centerAndExtend = calcCenterAndExtendOfProposalRegion(iProposalRegion);
                    classifyByCenterAndExtendAndAppendProtoobj(centerAndExtend);
                }
            }
        }


        if (enProcessAsStream && ctx.config__typeProtobjectSrc == "flow") {
            // compute protoobjects based on optical flow

            // downsamples "img" and "imgFrameBefore"
            var downscaledImg: Map2dRgb = ImageOperators.scale(ctx.img, Std.int(ctx.img.w*ctx.config__frameDiff_downsampleFactor));
            var downscaledImgFrameBefore: Map2dRgb = ImageOperators.scale(ctx.imgFrameBefore, Std.int(ctx.img.w*ctx.config__frameDiff_downsampleFactor));


            // * write out images to disk
            PpmExporter.export(downscaledImg, "outImgCurr.ppm");
            PpmExporter.export(downscaledImgFrameBefore, "outImgBefore.ppm");

            // * run optical flow anaysis
            var opticalFlowRes: {mapMag:Map2dFloat, mapAngle:Map2dFloat} = ProgramRunnerMotion.run("outImgCurr.ppm", "outImgBefore.ppm");

            // * compute x and y directions of flow
            var dirX: Map2dFloat;
            var dirY: Map2dFloat;
            
            /* code to translate between angle and magnitude representation to coordinate representation - commented because it's not necessary
            dirX = new Map2dFloat(opticalFlowRes.mapAngle.w, opticalFlowRes.mapAngle.h);
            dirY = new Map2dFloat(opticalFlowRes.mapAngle.w, opticalFlowRes.mapAngle.h);
            for (iy in 0...dirX.h) {
                for (ix in 0...dirX.w) {
                    var angle: Float = opticalFlowRes.mapAngle.readAtUnsafe(iy,ix);
                    var mag: Float = opticalFlowRes.mapMag.readAtUnsafe(iy,ix);

                    var dirXVal: Float = Math.tan(angle);
                    var dirYVal: Float = 1.0/Math.tan(angle); // cot(angle)

                    dirX.writeAtUnsafe(iy,ix,dirXVal*mag);
                    dirY.writeAtUnsafe(iy,ix,dirYVal*mag);
                }
            }
             */
            
            // maps are in reality already the dense flow vectors
            dirX = opticalFlowRes.mapMag;
            dirY = opticalFlowRes.mapAngle;

            // * compute proposal regions based on optical flow
            var allProposalRegions: Array<{rect:RectInt,id:Int}> = []; // all proposal regions, used for debugging  ...  ids may be reused, but this is not a problem because id's are not used for debugging
            
            
            
            var setting__flowToProposalsAlgorithm: String = "particle"; // "simple" or "particle",  is the algorithm on how to convert flow to "proposal-regions"
            
            
            if (setting__flowToProposalsAlgorithm == "particle") { // particle based tracking is chosen

                // helper to process a primary proposal region
                // definition: a "primary proposal region" is a region which is the direct output of the "particle based grouping" algorithm
                function processPrimaryProposalRegion(primaryProposalRegion) {

                    var secondaryProposalGenerationAlgo: String = "simpleCenterA"; // "none" or "simpleCenterA"
                    var secondaryProposalGenerationAlgo__simpleCenterAVaryExtendPixels: Float = 20.0; // how many pixels are varied?
                    var secondaryProposalGenerationAlgo__simpleCenterAVary__nSamples: Int = 10; // how many samples are done for each "primary proposal"

                    // TODO HIGH 13.08.2022< implement algorithm to iterate over possible regions close to the region, scanning for known proto-objects >

                    if (secondaryProposalGenerationAlgo == "none") { // no varying of the secondary center at all to find best known class
                        var primaryProposalcenterAndExtend = calcCenterAndExtendOfProposalRegion(primaryProposalRegion);
                        classifyByCenterAndExtend(primaryProposalcenterAndExtend);
                    }
                    else { // "simpleCenterA"

                        // algorithm:
                        // a) we vary the center and classify without revision, then we take the best classification (if there is one) and add it,
                        //    we also classify and add the center, just in case
                        
                        var primaryProposalcenterAndExtend = calcCenterAndExtendOfProposalRegion(primaryProposalRegion);

                        // * vary the center
                        {
                            var bestSimilarity: Float = -2.0;
                            var bestCenterAndExtend: {center:{x:Int,y:Int}, extend:Int} = null;

                            for (iSampleIdx in 0...secondaryProposalGenerationAlgo__simpleCenterAVary__nSamples) {
                                var x01: Float = ctx.miscRng.genFloat01();
                                var y01: Float = ctx.miscRng.genFloat01();
    
    
                                var xRelFloat: Float = -secondaryProposalGenerationAlgo__simpleCenterAVaryExtendPixels + x01*secondaryProposalGenerationAlgo__simpleCenterAVaryExtendPixels*2.0;
                                var yRelFloat: Float = -secondaryProposalGenerationAlgo__simpleCenterAVaryExtendPixels + y01*secondaryProposalGenerationAlgo__simpleCenterAVaryExtendPixels*2.0;
    
                                var xRelInt: Int = Std.int(xRelFloat);
                                var yRelInt: Int = Std.int(yRelFloat);
    
                                var secondaryProposalcenterAndExtend = {center:{x:primaryProposalcenterAndExtend.center.x+xRelInt,y:primaryProposalcenterAndExtend.center.y+yRelInt}, extend:primaryProposalcenterAndExtend.extend};
                                
                                
                                var secondaryProtoobjectDat: {item:ProtoobjectClassifierItem, similarity:Float} = classifyByCenterAndExtend(secondaryProposalcenterAndExtend, false);
                                
                                // decide best one
                                if (secondaryProtoobjectDat.similarity > bestSimilarity) {
                                    bestSimilarity = secondaryProtoobjectDat.similarity;
                                    bestCenterAndExtend = secondaryProposalcenterAndExtend;
                                }
                            }

                            // select best sample
                            if (bestSimilarity > -1.0) { // check to make sure that something was found
                                // classify and revise at best position it found
                                classifyByCenterAndExtend(bestCenterAndExtend, true);
                            }
                        }


                        // * add center and revise
                        classifyByCenterAndExtend(primaryProposalcenterAndExtend);
                    }
                }


                // * run algorithm
                ctx.particleBasedGrouping.process(dirX, dirY);

                // * convert groups to "region-proposals"
                for (iClusterPrimary in ctx.particleBasedGrouping.outCurrentFrameClusters) {
                    var iClusterPrimaryAabb = iClusterPrimary.calcAabb(); // calc AABB

                    var iPrimaryProposalRegion = {rect:new RectInt(Std.int(iClusterPrimaryAabb.min.x), Std.int(iClusterPrimaryAabb.min.y), Std.int(iClusterPrimaryAabb.max.x), Std.int(iClusterPrimaryAabb.max.y)), id:-1};

                    processPrimaryProposalRegion(iPrimaryProposalRegion);

                    allProposalRegions.push(iPrimaryProposalRegion);
                }
            }


            if (setting__flowToProposalsAlgorithm == "simple") {
                // algorithm: segementate motion into quadrants
                // TODO LOW< implement better algorithm which works for more complicated environments! >


                
                var directioncodeMaps: Array<Map2dBool> = [];
                for(j in 0...9) {
                    directioncodeMaps.push(new Map2dBool(dirX.w,dirX.h));
                }

                for (iy in 0...dirX.h) {
                    for (ix in 0...dirX.w) {
                        var dirXVal: Float = dirX.readAtUnsafe(iy,ix);
                        var dirYVal: Float = dirY.readAtUnsafe(iy,ix);

                        // compute directionCode
                        var dirCodeX: Int = 0;
                        if (dirXVal > ctx.config__motionSegmentation_ThresholdMin) {
                            dirCodeX = 1;
                        }
                        else if (-dirXVal > ctx.config__motionSegmentation_ThresholdMin) {
                            dirCodeX = -1;
                        }

                        var dirCodeY: Int = 0;
                        if (dirYVal > ctx.config__motionSegmentation_ThresholdMin) {
                            dirCodeY = 1;
                        }
                        else if (-dirYVal > ctx.config__motionSegmentation_ThresholdMin) {
                            dirCodeY = -1;
                        }


                        var dirCode = (dirCodeX+1) + (dirCodeY+1)*3; // compute directioncode

                        // write out to map
                        directioncodeMaps[dirCode].writeAtUnsafe(iy,ix,true);
                    }
                }


                // segment each direction code map
                for (j in 0...9) {

                    // * compute proposal regions
                    var proposalRegions: Array<{rect:RectInt,id:Int}> = RegionProposalGenerator.cluster(directioncodeMaps[j]);
                    

                    // we use the proposals as regions for classification of protoobjects
                    for (iProposalRegion in proposalRegions) {
                        allProposalRegions.push(iProposalRegion); // add for debugging
                        
                        var centerAndExtend = calcCenterAndExtendOfProposalRegion(iProposalRegion);
                        classifyByCenterAndExtendAndAppendProtoobj(centerAndExtend);
                    }
                }
            }


            
            var enDebugProposalRegionsFromMotionToGui: Bool = true;
            // draw debugging GUI of proposal-regions from motion
            {
                if (enDebugProposalRegionsFromMotionToGui) {
                    // debug proposal-regions to GUI
    
                    var s: String = "";
                    for( iProposalRegion in allProposalRegions) {
                        var s2: String = 'b ${iProposalRegion.rect.minx} ${iProposalRegion.rect.miny} ${iProposalRegion.rect.maxx} ${iProposalRegion.rect.maxy}';
                        trace(s2);
                        s = s + s2 + "\n";
                    }
    
                    ExtA.update(s); // send to display with GUI
                }
            }

            // transfer "allProposalRegions" 
            {
                ctx.lastFrameAllProposalRegions = allProposalRegions;
            }
        }


        // probabilistic motion estimator
        if (enProcessAsStream && ctx.config__typeProtobjectSrc == "prob0") {
            ctx.visionProbMotion.imgTminusOne = null; //TODO;
            ctx.visionProbMotion.imgTzero = null; //TODO;
            ctx.visionProbMotion.doWork();

            // translate prototypes from probabilistic motion estimator to our format
            // TODO TODO TODO TODO TODO TODO TODO
            // TODO TODO TODO TODO TODO TODO TODO
        }



        // a) use prototype classifier to classify all objects visible in scene
        {
            

            var frameSizeSet: Array<Int> = []; // array of framesizes to check, we sample multiple framesizes for a size invariant classification of proto-objects
            frameSizeSet.push(Std.int(ctx.img.w/5.0));
            frameSizeSet.push(Std.int(ctx.img.w/3.0)); // for big protoobjects
            
            // commented because it is to small - TODO TECH< we need to find a better way to find regions of small protoobjects! >
            //frameSizeSet.push(Std.int(ctx.img.w/9.0)); // for small protoobjects



            // iterate over framesizes
            for (iFramesize in frameSizeSet) {

                var config__protoobjectSubframe_inverseIncrement: Float = 3.0; // config - how many times is the stepsize divided of the framesize for the subframe for protoobjects

                for (iGridYmul in 0...Std.int( ctx.img.h / (iFramesize/config__protoobjectSubframe_inverseIncrement))) {
                    for (iGridXmul in 0...Std.int( ctx.img.w / (iFramesize/config__protoobjectSubframe_inverseIncrement))) {
                        // compute center of iterated grid position
                        var iCenterX: Int = Std.int(iGridXmul * (iFramesize/config__protoobjectSubframe_inverseIncrement));
                        var iCenterY: Int = Std.int(iGridYmul * (iFramesize/config__protoobjectSubframe_inverseIncrement));


                        var stimulusItemsA: Array<{pos:{x:Int,y:Int},id:Int}> = [];
                        var sampledCenter: {x:Int,y:Int} = {x:iCenterX,y:iCenterY};

                        var sampledCenterAndExtend = {center:{x:iCenterX,y:iCenterY}, extend:iFramesize};

                        /* commented because obsolete
                        stimulusItemsA = collectStimulusItemsOfSubFrame(sampledCenter, iFramesize);
                        
                        // map to relative positions
                        var stimulusItems: Array<{pos:{x:Float,y:Float},id:Int}> = stimulusItemsA.map(iv -> mapAbsolutePosToRelative(sampledCenter, iv, iFramesize));
                        
                        // FIXME< this is a hack to remove id's -1 where the ART classifier returned -1, this shouldn't happen and is a bug in ART2 implementation >
                        stimulusItems = stimulusItems.filter(iv -> return iv.id != -1);
            
                        // * compute protoobject coresponding with the perceived protoobject at the given position
                        var protoobjectAtCenter: ProtoobjectClassifierItem = ProtoobjectClassifier.classify(stimulusItems, ctx.cycleEpoch, ctx.prototypeClassifierCtx); // classify samples to get level1 classification
                        
                        
                        // store "protoobjectAtCenter"
                        protoObjects.push({center:sampledCenter,protoobj:protoobjectAtCenter});
                        */
                        classifyByCenterAndExtendAndAppendProtoobj(sampledCenterAndExtend);
                    }
                }
            }



            // report "protoObjects" for this frame
            {
                ctx.sinkProtoobjects.reportProtoobjectsOfFrame(protoObjects);
            }

            // output protoobjects as narsese
            {
                for (iProtoobject in protoObjects) {
                    // map evidence counter to confidence

                    // TODO< add more factors into confidence calculations!
                    var c: Float = 0.99 * (1.0 - Math.exp(-1.0*0.01*iProtoobject.protoobj.evidenceCount));

                    if (ctx.emitNarsese) {
                        Sys.println('OUTN:<{(protoobjcls${iProtoobject.protoobj.id}*${Std.int(iProtoobject.center.x/10.0)}Q${Std.int(iProtoobject.center.y/10.0)})} --> detectedprotoobj>. {1.0 $c}:|:');
                    }
                }
            }
        }

        // b) flush container of level0 samples
        ctx.level0SampleContainer = [];



        // send frame to situation detector
        {
            var entityClasses: Array<Int> = [];
            // FIXME< we need different local variables for "protoObjects" visible in the scene!
            //        one for all tried and recognized and one for the really detected
            entityClasses = protoObjects.map(iObservedProtoobject -> iObservedProtoobject.protoobj.id);

            VXSituationDetector.observe(entityClasses,   ctx.vxSituationDetectorCtx);
        }

        // finish situation
        {
            var isSituationEnded = (ctx.frameCounter % Std.int(/*0.7*30.0*/3)) == 0; // 30 seconds
            if (isSituationEnded) {
                VXSituationDetector.finishCurrentSituation(ctx.frameCounter,   ctx.vxSituationDetectorCtx);

                var observedHdVectorOfSituation: Array<Float> = ctx.vxSituationDetectorCtx.currentSituationHdVector;
                VXSitationClassifier.observeSituation(observedHdVectorOfSituation, ctx.frameCounter,   ctx.vxSitationClassifierCtx);
            }
        }


        // copy frame
        ctx.imgFrameBefore = ctx.img;
    }

    // helper to compute convolution
    // /return array of different convolutions
    public static function _helper__calcConv(ctx:Vis2Ctx): Array<Map2dRgb> {
        var convResArr: Array<Map2dRgb> = [];

        { // convolution
            // TODO 11.12.2021 : implemented array of kernels and convolution results and check if the kernels look good!

            var lamdba: Float = 1 * (Math.PI/4);


            for (iKernelIdx in 0...ctx.config__conv__nConvolutionOrientations) {
                var kernel0: Map2dFloat;
                
                var phiRel: Float = iKernelIdx / (ctx.config__conv__nConvolutionOrientations-1); // relative angle from 0 degrees to 180 degrees
                var phi: Float = phiRel * ((Math.PI*2)/2);
                kernel0 = GaborKernel.generateGaborKernel(15, phi, lamdba, 0.0, 1.0);
        
        
                // TODO< compute gray channel and extract then ! >
                var imgR: Map2dFloat = ImageOperators.extractChannelRed(ctx.img);
                
                var convResult0: Map2dFloat = ImageOperators.conv1(imgR, kernel0); // compute convolution


                var convResult0AsRgb: Map2dRgb = ImageOperators.convOneChannelToRgb(convResult0); //& convert to RGB because some functions are only implemented for RGB

                convResArr.push(convResult0AsRgb);
            }


            /*
            var kernel0: Map2dFloat;
            {
                var phi: Float = 0 * (Math.PI/4);
                kernel0 = GaborKernel.generateGaborKernel(15, phi, lamdba, 0.0, 1.0);
            }
    
    
            // TODO< compute gray channel and extract then ! >
            var imgR: Map2dFloat = ImageOperators.extractChannelRed(ctx.img);
    
            convResult0 = ImageOperators.conv1(imgR, kernel0); // compute convolution
    
            // DBG - dump to file
            ///if(false) PpmExporter.export(ImageOperators.convOneChannelToRgb(convResult0), 'dbgOut_conv0_${dbgFrameNumber}.ppm');
            ///if(false) PpmExporter.export(img, 'dbgOut_input_${dbgFrameNumber}.ppm');


            var kernel1: Map2dFloat;
            {
                var phi: Float = 1 * (Math.PI/4);
                kernel1 = GaborKernel.generateGaborKernel(15, phi, lamdba, 0.0, 1.0);
            }

            convResult1 = ImageOperators.conv1(imgR, kernel1); // compute convolution
            */
        }

        //var convResult0AsRgb: Map2dRgb = ImageOperators.convOneChannelToRgb(convResult0); //& convert to RGB because some functions are only implemented for RGB
        //var convResult1AsRgb: Map2dRgb = ImageOperators.convOneChannelToRgb(convResult1); //& convert to RGB because some functions are only implemented for RGB

        //return [convResult0AsRgb,convResult1AsRgb];

        return convResArr;
    }

    static var threadPool: FixedThreadPool = new FixedThreadPool(3);
    //static var accuMutex0: Mutex = new Mutex();
    static var accuLock0: Lock;

    // helper for execution of eye saccade
    public static function eyeSaccade__exec2(saccade:Array<Vec2>, center:Vec2,  ctx: Vis2Ctx, enArtUpdate: Bool = true): Array<{saccadeVertexIdx:Int,x:Int,y:Int,class_:Int}> {
        var accu: Array<{saccadeVertexIdx:Int,x:Int,y:Int,class_:Int}> = [];

        var iSaccadeVertexIdx: Int = -1;
        for (iSaccadeRelativePosition in saccade) {
            iSaccadeVertexIdx++;
            
            var absolutePosition: Vec2 = Vec2.add(center, Vec2.scale(
                iSaccadeRelativePosition, 
                ctx.img.w*       (ctx.param__SaccadeLevel0__cropRatio*ctx.param__SaccadeLevel0__saccadeRatio)    ));

            if(0>=1) Sys.println('DBG: saccade: exec at position=<${absolutePosition.x} ${absolutePosition.y}>');


            // crop at absolute position from environment
            //var stimulusImageRgb: Map2dRgb = ImageOperators.subImg(ctx.img, Std.int(absolutePosition.x) - Std.int(8/2), Std.int(absolutePosition.y) - Std.int(8/2), 8, 8);
            var outSize: Int = ctx.foveaWidthPixels; // must be divisable by 2
            
            
            ///commented because this isn't doing any convolution, and we are using convolution
            ///var stimulusImageRgb: Map2dRgb = ImageOperators.subImgWithScalingByCenter(ctx.img, {x:Std.int(absolutePosition.x),y:Std.int(absolutePosition.y)}, Std.int(ctx.img.w*0.08), outSize);
            ///
            ///var stimulusImageMonochrome: Map2dFloat = ImageOperators.extractChannelRed(stimulusImageRgb);
            ///
            ///var stimulusVec: Array<Float> = convMap2dFloatToVec(stimulusImageMonochrome);

            var stimulusVec: Array<Float> = []; // accumulator for stimulus vector

            for (iConvIdx in 0...ctx.convolutionImages.length) { // iterate over different convolutions
                var stimulusImageConvRgb: Map2dRgb = ImageOperators.subImgWithScalingByCenter(ctx.convolutionImages[iConvIdx], {x:Std.int(absolutePosition.x),y:Std.int(absolutePosition.y)}, Std.int(ctx.img.w*ctx.param__SaccadeLevel0__cropRatio), outSize);
                
                var stimulusImageConvMonochrome: Map2dFloat = ImageOperators.extractChannelRed(stimulusImageConvRgb);
                
                var stimulusPartVec: Array<Float> = convMap2dFloatToVec(stimulusImageConvMonochrome);
                stimulusVec = stimulusVec.concat(stimulusPartVec);
            }



            // idea: brighten stimulus+normalization
            //       
            //       Here we normalize the complete input, which seems to be biological plausible (as advocated by Grossberg).
            //       This has a nice sideeffect to map the stimulus into a [0.0;1.0] range
            
            // HACK< add small value to avoid singularity when all values are zero >
            // TODO LOW< implement better handling to only do this when all values are exactly 0.0 ! >
            stimulusVec[0] += 1e-7;

            var stimulusNormalizedVec: Array<Float> = BRealvectorUtils.normalize(stimulusVec);
            var classifierInputVec: Array<Float> = VecHelper3.addScalar(stimulusNormalizedVec, 1e-7); // add a very small value to avoid 0.0, which ART doesn't seem to "like" at all

            // DBG
            //trace(stimulusVec);
            //trace(classifierInputVec);


            {
                var iSaccadeVertexIdx2: Int = iSaccadeVertexIdx; // copy iterator because else it's buggy because of an race condition
                threadPool.run(() -> {
                    //trace('a1 ${iSaccadeVertexIdx2}');

                    // * classify with defered learning
                    var classifiedClass: Int = ctx.artCtxs[iSaccadeVertexIdx2].calc(classifierInputVec);
                    
                    //accuMutex0.acquire();
                    accuLock0.wait();
                    
                    //trace('a2');
                    
                    accu.push({saccadeVertexIdx:iSaccadeVertexIdx2, x:Std.int(absolutePosition.x),y:Std.int(absolutePosition.y),class_:classifiedClass});
                    
                    
                    //accuMutex0.release();
                    accuLock0.release();
                    
                    //trace('a3');
                });
            }
        }

        //trace('enter busy');

        // busy waiting loop
        // TODO LOW< convert this to non-busy waiting loop!!! >
        while (accu.length < saccade.length) {
            Sys.sleep(0.0);
        }

        //trace('exit busy');
        
        if (enArtUpdate) {
            // we need to update ART classifier
            for (iIdx in 0...saccade.length) {
                ctx.artCtxs[iIdx].calcUpdate();
            }
        }


        // we need to sort by index of saccade!
        accu.sort((a, b) -> MathUtils2.sign(a.saccadeVertexIdx - b.saccadeVertexIdx));

        ///for(iv in accu) {
        ///    trace(iv.saccadeVertexIdx);
        ///}

        return accu;
    }

    // execute eye cassade
    // /return array of classifications for each vertex of the path
    public static function eyeSaccade__exec(saccade:Array<Vec2>, center:Vec2,  ctx: Vis2Ctx): Array<Int> {
        var enCollectSamplesIntoContainer: Bool = true; // collect the samples into a level0 container?
        
        var pathClasses: Array<Int> = [];

        var pathRecorder: Array<{x:Int,y:Int,class_:Int}> = []; // accumulates the path taken, used for debugging

        var accu: Array<{saccadeVertexIdx:Int,x:Int,y:Int,class_:Int}> = eyeSaccade__exec2(saccade, center,  ctx);

        // now we need to make sense of the path
        {
            for(iSaccadeVertexIdx in 0...saccade.length) {
                var iAccuV = accu[iSaccadeVertexIdx];

                // remember for path-recorder
                pathRecorder.push({x:iAccuV.x,y:iAccuV.y,class_:iAccuV.class_});

                // collect for sampleLevel0container
                if (enCollectSamplesIntoContainer) {
                    ctx.level0SampleContainer.push({pos:{x:iAccuV.x,y:iAccuV.y},id:iAccuV.class_});
                }


                pathClasses.push(iAccuV.class_);
            }
        }



        { // report to sink (for debugging etc)
            ctx.sinkEyeSaccades.reportEyeSaccadePath(pathRecorder);
        }


        // print diagnostics
        ////trace('diagnostics.time.ArtAccu=${ctx.diagnostics__timeArtAccu}');

        return pathClasses;
    }

    // generator for relative positions of eye saccade
    public static function eyeSaccadePathGen__generateRandomEyeSaccade (count:Int, imgWidth:Int, rng: Rng0): Array<Vec2> {
        var resPath: Array<Vec2> = [new Vec2(0.0,0.0)];

        //var relativeFactor: Float = 8.0; // relative factor used to compute relative fovea change

        for (i in 1...count) {
            var x = MathHelper2.rngRange2(-1.0, 1.0, rng);
            var y = MathHelper2.rngRange2(-1.0, 1.0, rng);
            resPath.push( new Vec2(x,y) );
        }

        return resPath;
    }




    // helper to convert image to vector
    public static function convMap2dFloatToVec (map:Map2dFloat): Array<Float> {
        var res = [];
        for (iy in 0...map.h) {
            for (ix in 0...map.w) {
                res.push(map.readAtUnsafe(iy,ix));
            }
        }
        return res;
    }

}

// context for vision processing
class Vis2Ctx {
    public var emitNarsese: Bool = true;

    // parameters / settings
    public var paramSaccadesNMax: Int = 100; // maximal number of saccades to maintain, is a AIKR parameter
    public var saccadePositionSimThreshold: Float = -1.0; // threshold of similarity of positions which is used to determine if saccade is similar enough to existing ones
    public var foveaWidthPixels: Int = 2; // width of fovea in pixels


    public var param__SaccadeLevel0__cropRatio: Float = 0.08; // ratio of how "wide" the sub-image which is perceived by the fovea is       relative to image width 

    public var param__SaccadeLevel0__saccadeRatio: Float = 1.2; // ratio of how far away a vertex of a eye saccade can deviate,   relative to image width 
                                                                // how much does the fovea jump around relative to image width and "jumpness factor" of the fovea center?



    public var config__motionSegmentation_ThresholdMin: Float = 1.0; //  0.21; //0.09; // minimal threshold on when to register as motion


    public var config__conv__nConvolutionOrientations: Int = 3; // how many orientations are used for convolution?



    public var config__typeProtobjectSrc: String = "flow"; // "diff" or "flow"
    public var config__frameDiff_downsampleFactor: Float = 1.0/6;
    public var config__frameDiff_threshold: Float = 3.0*0.1; // threshold for per pixel check for enough change per pixel  - manhattan distance



    // reporters
    public var sinkEyeSaccades: SinkEyeSaccades = new SinkEyeSaccadesNull(); // sink for eye saccades reported to, useful for debugging etc.
    public var sinkProtoobjects: SinkProtoobjects = new SinkProtoobjectsNull(); // sink for protoobjects to report to for each frame





    public var level0SampleContainer: Array<{pos:{x:Int,y:Int},id:Int}> = []; // container with samples of level0, flushed after each frame



    public var img: Map2dRgb; // current presented input image


    public var imgFrameBefore: Map2dRgb; // presented input image frame before on timestep



    public var convolutionImages: Array<Map2dRgb>; // images of result of convolution, used internally!


    public var artClassifier: MyArt_v1; // classifier used to classify raw low level stimulus
    public var artCtxs: Array<ArtCtx> = []; // contexts for art classification in parallel


    // IS:component
    public var particleBasedGrouping: ParticleBasedGroupingAlgo = new ParticleBasedGroupingAlgo();



    // IS:component
    public var vxSituationDetectorCtx: VXSituationDetectorContext;

    // IS:component
    public var vxSitationClassifierCtx: VXSitationClassifierCtx;



    // proposal regions of the last frame, can be used in any 'context'
    public var lastFrameAllProposalRegions: Array<{rect:RectInt,id:Int}> =null;




    public var saccadeRewardCtx: AttCtx = new AttCtx();


    // set of all known paths with different encodings
    // set is maintained under AIKR
    //public var saccadeSet: Array<DecoratedPathWithHdEncoding> = [];

    //public var saccadeSet4: Array<DecoratedPathWithHdEncoding> = [];

    // set of all known paths with different encodings
    // set of saccades by length of saccade
    // * set is maintained under AIKR
    // [0] saccades for length 0 (there are none)
    // [1] saccades for length 1 (there are none)
    // [2] saccades for length 2 (there are none)
    // [3] saccades for length 3
    // [4] saccades for length 4
    // [5] saccades for length 5
    public var saccadeSetByLength: Array<  Array<DecoratedPathWithHdEncoding>  >;


    // classifier for the prototypes of protoobjects which is fed with classification+relative position of datapoints from the "low level" classifier (in our case ART2)
    public var prototypeClassifierCtx: ProtoobjectClassifierCtx = null;



    public var visionProbMotion: VisionProbabilisticMotion0 = new VisionProbabilisticMotion0();



    // the used strategy for the 
    public var foveaCenterProposalStrategy: FoveaCenterPropsalStrategy = new FoveaCenterPropsalStrategy();


    // running variables
    public var saccadeUniqueIdCounter: Int = 1; // counter used to generate unique ids of saccades, mainly used to "name" a saccade
    public var cycleEpoch: Int = 0; // used to differentiate between different cycles, used for resource allocation
    public var frameCounter: Int = 0; // used to differentiate between frames

    // permutations
    public var permVecX: Array<Int>; // permutation for x vector
    public var permVecY: Array<Int>; // permutation for y vector
    public var permVecPositionsShuffle: Array<Int>; // permutation to shuffle around position vector

    // rng
    public var eyeSaccadeRng: Rng0 = new CryptoRng0("4243"); // rng used for generation of eye saccades
    public var foveaCenterRng: Rng0 = new CryptoRng0("4321"); // rng used for generation of center of fovea
    public var artRng: Rng0 = new CryptoRng0("4332"); // rng used for ART initialization
    public var miscRng: Rng0 = new CryptoRng0("32"); // rng for other stuff


    // diagnostics
    public var diagnostics__timeArtAccu: Float = 0.0; // accumulator for overall time spent for ART
    public var diagnostics__timeCycleAccu: Float = 0.0; // accumulator for overall time spent in cycle

    public function new() {
        var rng: Rng0 = new CryptoRng0("4242");

        permVecX = BBitvectorUtils.genPerm(60, rng);
        permVecY = BBitvectorUtils.genPerm(60, rng);
        permVecPositionsShuffle = BBitvectorUtils.genPerm(60, rng);


        saccadeSetByLength = [];
        saccadeSetByLength.push([]); // for length 0
        saccadeSetByLength.push([]); // for length 1
        saccadeSetByLength.push([]); // for length 2
        saccadeSetByLength.push([]); // for length 3
        saccadeSetByLength.push([]); // for length 4
        saccadeSetByLength.push([]); // for length 5
    }
}


// helper which provides helpers to manage saccades
class SaccadeSetUtils {
    public static function appendSaccade(saccade: PathWithHdEncoding,  ctx: Vis2Ctx): DecoratedPathWithHdEncoding {
        var saccadeUniqueId: Int = ctx.saccadeUniqueIdCounter++;
        var decoratedSaccade: DecoratedPathWithHdEncoding = new DecoratedPathWithHdEncoding(saccade, saccadeUniqueId);

        // NOTE< we don't enforce AIK here! >
        if (saccade.pathSaccade.pathItems.length > ctx.saccadeSetByLength.length) {
            Sys.println('warn: tried to append saccade which is to long!');
            return null;
        }
        ctx.saccadeSetByLength[saccade.pathSaccade.pathItems.length].push(decoratedSaccade);

        ////Sys.println('DBG specific nSaccadeSet=${ctx.saccadeSetByLength[saccade.pathSaccade.pathItems.length].length}');

        return decoratedSaccade;
    }

    public static function lookupBestSaccadeByPositionAndVertexClass(saccade: PathWithHdEncoding,  ctx: Vis2Ctx): DecoratedPathWithHdEncoding {
        return lookupBestSaccadeByPositionAndVertexClass2(saccade, ctx.saccadeSetByLength[saccade.pathSaccade.pathItems.length],   ctx);
    }
    

    public static function lookupBestSaccadeByPositionAndVertexClass2(saccade: PathWithHdEncoding, saccadeSet: Array<DecoratedPathWithHdEncoding>,  ctx: Vis2Ctx): DecoratedPathWithHdEncoding {
        var bestHitSaccadePositionSim: Float = -1.0;
        var bestHitSaccade: DecoratedPathWithHdEncoding = null;

        for (itSaccadeWithPayload in saccadeSet) {
            var itSaccade: PathWithHdEncoding = itSaccadeWithPayload.payload;

            var sim: Null<Float> = VSaccadeUtilities.cmpSaccades(saccade, itSaccade, 0, 0);
            if (sim == null) { // isn't similar at all?
                continue;
            }
            if (sim > bestHitSaccadePositionSim) {
                bestHitSaccadePositionSim = sim;
                bestHitSaccade = itSaccadeWithPayload;
            }
        }
        
        if (false) Sys.println('DBG: lookupBestSaccade: bestHitSaccadePositionSim=${bestHitSaccadePositionSim}');
        if (bestHitSaccadePositionSim < ctx.saccadePositionSimThreshold ) { // wasn't a good saccade with similar positions found?
            return null;
        }

        return bestHitSaccade;
    }

    // used to keep memory under AIK
    // this has to be called from time to time by the main-loop
    public static function saccadeGc(ctx: Vis2Ctx) {
        
        for (saccadeSetIdx in 0...ctx.saccadeSetByLength.length) {
            var iSaccadeSet: Array<DecoratedPathWithHdEncoding> = ctx.saccadeSetByLength[saccadeSetIdx];
        
            var inplace: Array<DecoratedPathWithHdEncoding> = iSaccadeSet.copy();
    
            // * sort by usefulness
            // TODO< better sorting criterion! >
            inplace.sort((a, b) -> MathUtils2.sign(  Math.exp(-0.08*(ctx.cycleEpoch - b.cycleEpochLastUse)) - Math.exp(-0.08*(ctx.cycleEpoch - a.cycleEpochLastUse))  ));
    
            // DBG
            if (false) {
                for(iv in inplace) {
                    trace(iv.cycleEpochLastUse);
                }
            }
    
            var inplaceKeep: Array<DecoratedPathWithHdEncoding> = inplace.slice(0, ctx.paramSaccadesNMax);
    
            ////trace('GC lenbefore=${ctx.saccadeSetByLength[saccadeSetIdx].length}');
            ctx.saccadeSetByLength[saccadeSetIdx] = inplaceKeep; // keep under AIK
            ////trace('GC lenafter=${ctx.saccadeSetByLength[saccadeSetIdx].length}');
        }
    }


    public static function castPathToPathWithHdEncoding(eyesaccadePath: EyesaccadePath,  ctx:Vis2Ctx): PathWithHdEncoding {
        var vecLen: Int = 60; // length of used vector to encode all of it
        
        // convert the explicit representation of the positions to a representation useful for HD-computing
        var vecPositions: Array<Float> = BRealvectorUtils.genZero(vecLen); // used as accumulator for the HD-representation of the positions

        for (iVertex in eyesaccadePath.pathItems) { // iterate over vertices of path
            var xInRange: Float = MathUtils2.convTo01Range(iVertex.relRelPos.y, -1.0, 1.0);
            var yInRange: Float = MathUtils2.convTo01Range(iVertex.relRelPos.y, -1.0, 1.0);
            
            var vecXReal: Array<Float> = BRealvectorUtils.convRealValue01ToVec(xInRange, vecLen, Std.int(vecLen/7));
            var vecYReal: Array<Float> = BRealvectorUtils.convRealValue01ToVec(yInRange, vecLen, Std.int(vecLen/7));
            
            //trace(""); // DBG
            //trace('X=$vecXReal'); // DBG
            //trace('Y=$vecYReal'); // DBG

            var vecXPermutatedReal: Array<Float> = BRealvectorUtils.perm(vecXReal, ctx.permVecX);
            var vecYPermutatedReal: Array<Float> = BRealvectorUtils.perm(vecYReal, ctx.permVecY);

            // * merge vectors to single vector
            vecPositions = BRealvectorUtils.perm(vecPositions, ctx.permVecPositionsShuffle); // use permutation to "shuffle" around the vector so we can in principle stuff in any number of real-values into it!

            vecPositions = BRealvectorUtils.add(vecPositions, vecXPermutatedReal);
            vecPositions = BRealvectorUtils.add(vecPositions, vecYPermutatedReal);
        }

        //trace(vecPositions); // DBG

        return new PathWithHdEncoding(vecPositions, eyesaccadePath);
    }
}

// helper which provides other helpers
class SaccadeUtils2 {
    // function to compute a random offset
    public static function calcOffset(ctx: Vis2Ctx): Vec2 {
        var relX: Float = MathUtils2.convTo01Range(ctx.eyeSaccadeRng.genFloat01(), -10.0, 10.0);
        var relY: Float = MathUtils2.convTo01Range(ctx.eyeSaccadeRng.genFloat01(), -10.0, 10.0);
        return new Vec2(relX, relY);
    }

    // executes saccade and creates a new saccade by adding one vertex
    // /param seedPath the actual expected path of saccade which will be compared
    // /param center center of executed eye saccade
    public static function saccadeComputeContinuation(seedPath: PathWithHdEncoding, center:Vec2,  ctx: Vis2Ctx): DecoratedPathWithHdEncoding {
        // extract relative relative positions
        var verticesRelRelPos: Array<Vec2> = seedPath.pathSaccade.pathItems.map(iv -> iv.relRelPos);


        // helper to compute the path with is tried
        function calcTriedPath(continuationRel: Vec2): Array<Vec2> {
            var x: Array<Vec2> = verticesRelRelPos.copy();
            x.push(continuationRel); // add relative for continuation

            // build contination of the path without the first vertex
            var y = x.slice(1); // remove first vertex
            y[0] = new Vec2(0.0,0.0); // set first vertex to null vector because this is the definition of the relative positions of a path

            return y;
        }        




        // algorithm: we must
        // * execute seed path
        // * compare result
        // * extend it with one vertex
        //    * add the new saccade if no similar one exists

        
        var resFirstPath: Array<{saccadeVertexIdx:Int,x:Int,y:Int,class_:Int}> = PROTOVis2.eyeSaccade__exec2(verticesRelRelPos, center,  ctx, false);

        for (iIdx in 0...resFirstPath.length) {
            // compare expected class to observed class
            if (resFirstPath[iIdx].class_ != seedPath.pathSaccade.pathItems[iIdx].class_) {
                return null; // give up
            }
        }

        // generate and test continuation
        var usedContinuationOffset: Vec2 = calcOffset(ctx);


        // compute the path of a possible continuation
        var triedPath: Array<Vec2> = calcTriedPath(usedContinuationOffset);


        // execute tried path

        // * cast to SaccadeWithHdEncoding
        
        var resContinuationPath: Array<{saccadeVertexIdx:Int,x:Int,y:Int,class_:Int}>;
        {
            resContinuationPath = PROTOVis2.eyeSaccade__exec2(triedPath, Vec2.add(center, verticesRelRelPos[1]),  ctx, false);
        }


        /* commented because not necessary
        // make sense of result of "resContinuationPath"

        // search for best match which is sufficiently similar
        var bestMatchOfContinuationPath: DecoratedPathWithHdEncoding = null;
        {
            // we need to merge class and relative position
            var eyesaccadePath: EyesaccadePath = new EyesaccadePath();
            for (iIdx in 0...resContinuationPath.length) {
                var iRelRelPos: Vec2 = triedPath[iIdx];
                var iClass_: Int = resContinuationPath[iIdx].class_;
                eyesaccadePath.pathItems.push(new PathItem(iRelRelPos, iClass_));
            }

            var saccadeWithHdEncoding: PathWithHdEncoding = SaccadeSetUtils.castPathToPathWithHdEncoding(eyesaccadePath,  ctx);
            bestMatchOfContinuationPath = SaccadeSetUtils.lookupBestSaccadeByPositionAndVertexClass2(saccadeWithHdEncoding, ctx.saccadeSet,  ctx);
        }

        // create new full saccade if there wasn't a sufficiently similar full saccade
        {
            if (bestMatchOfContinuationPath != null) {
                // TODO
            }
        }
        */







        // build full saccade and check if another one already exists, create new one if not
        {
            // we need to merge class and relative position
            var eyesaccadePath: EyesaccadePath = new EyesaccadePath();
            for (iItem in seedPath.pathSaccade.pathItems) {
                eyesaccadePath.pathItems.push(iItem);
            }

            {
                var lastVertexOffset: Vec2 = usedContinuationOffset;
                var lastVertexClass: Int = resContinuationPath[resContinuationPath.length-1].class_;
                eyesaccadePath.pathItems.push(new PathItem(lastVertexOffset, lastVertexClass));
            }

            var saccadeWithHdEncoding: PathWithHdEncoding = SaccadeSetUtils.castPathToPathWithHdEncoding(eyesaccadePath,  ctx);
            var bestMatchOfFullPath: DecoratedPathWithHdEncoding = SaccadeSetUtils.lookupBestSaccadeByPositionAndVertexClass2(saccadeWithHdEncoding, ctx.saccadeSetByLength[4],  ctx);
            if (bestMatchOfFullPath == null) { // was no full path found?
                // create a new one

                // * cast to SaccadeWithHdEncoding
                var saccadeWithHdEncoding: PathWithHdEncoding = SaccadeSetUtils.castPathToPathWithHdEncoding(eyesaccadePath,  ctx);

                var storedCandidateSaccade: DecoratedPathWithHdEncoding  = SaccadeSetUtils.appendSaccade(saccadeWithHdEncoding,   ctx);
                storedCandidateSaccade.cycleEpochLastUse = ctx.cycleEpoch; // we need to update this to know which saccade was used last for GC
                return storedCandidateSaccade;
            }
            return bestMatchOfFullPath;
        }
    }
}





// used to generate proposals of center position of fovea
//   criterion could be  heatmap by change which is a proxy of motion, etc.
class FoveaCenterPropsalStrategy {

    public function new() {}

    public function calcNextProposalPos(rng:Rng0, imagesize: {w:Int,h:Int}): Vec2 {
        var centerX: Int = Std.int(imagesize.w/2 +   MathHelper2.rngRange2(-imagesize.w/2.0, imagesize.w/2.0, rng));
        var centerY: Int = Std.int(imagesize.h/2 +   MathHelper2.rngRange2(-imagesize.h/2.0, imagesize.h/2.0, rng));
        //return new Vec2(16.0 + MathHelper2.rngRange2(-16.0/2.0, 16.0/2.0, rng), 16.0 + MathHelper2.rngRange2(-16.0/2.0, 16.0/2.0, rng));
        return new Vec2(centerX,centerY);
    }
}



class MathHelper2 {
    // helper
    public static function rngRange2(low:Float, high:Float, rng: Rng0): Float {
        return low + (high-low)*rng.genFloat01();
    }
}


// custom vector math helper
class VecHelper3 {
    // add scalar value
    // usually used to "brighten" vector
    public static function addScalar(vec: Array<Float>, val: Float): Array<Float> {
        var res: Array<Float> = [];
        for(iv in vec) {
            res.push(iv+val);
        }

        return res;
    }
}





// interface used to report eye saccades
// is useful for debugging/reporting
interface SinkEyeSaccades {
    // report a path with 
    function reportEyeSaccadePath(path:Array<{x:Int,y:Int,class_:Int}>): Void;
}

class SinkEyeSaccadesNull implements SinkEyeSaccades {
    public function new() {}
    public function reportEyeSaccadePath(path:Array<{x:Int,y:Int,class_:Int}>) {}
}



// interface used for reporting protoobjects of a frame
interface SinkProtoobjects {
    // report all protoobjects for a frame
    function reportProtoobjectsOfFrame(objs:Array<{center:{x:Int,y:Int},protoobj:ProtoobjectClassifierItem}>): Void;
}

class SinkProtoobjectsNull implements SinkProtoobjects {
    public function new() {}
    public function reportProtoobjectsOfFrame(objs:Array<{center:{x:Int,y:Int},protoobj:ProtoobjectClassifierItem}>) {}
}





// helper class to execute external scripts
class ExecProgramsUtils {
    public static function grab() {
        var p: Process = new Process('python3 ./pyUtils/GrabCamera.py');
        p.exitCode(); // wait till the termination of the program
    }

    // helper to convert the grabbed image from the video camera
    public static function convertGrabbedImage(srcName: String, destName:String) {
        {
            //sys.FileSystem.deleteFile('./'+destName);
        }
        
        var cmd: String = 'convert $srcName -compress none $destName';
        trace(cmd);
        var p: Process = new Process(cmd);
        p.exitCode(); // wait till the termination of the program

        {
            var filecontent: String = sys.io.File.getContent(srcName);

            var fileContentHash: String = haxe.crypto.Md5.encode(filecontent);
            trace('A hash=${fileContentHash}');
        }

        {
            var filecontent: String = sys.io.File.getContent(destName);

            var fileContentHash: String = haxe.crypto.Md5.encode(filecontent);
            trace('B hash=${fileContentHash}');
        }
    }
}









// DONE LOW< add reading of ppm of movie of natural image >

// DONE vision: saccade < fix similarity calculation of saccade so it is more sensivitve to the RelRel positions >

// DONE MID diagnostics< add latex report for microactions for debugging >

// DONE protobjects< make use of ProtoobjectClassifierCtx when we are done sampling from the frame!!! >

// DONE protoobjects< implement Sink for protoobjects in "EntryVisionManualTest0.hx" to add the protoobjects detected in a frame to the generated latex-report! >

// DONE HIGH 1.08.2022 processing: use ProgrammRunnerMotion.hx to compute optical motion
// DONE HIGH 1.08.2022 processing: use optical motion for proposal generation!!!


// HALFDONE LOW< implement GC  by age, usage, last usage >







// TODO MID 20.07.2022 preprocessing< add more convolution orientations! >


// TODO MID 20.07.2022 tooling< hook up to ONA with a python script and pass output of vision channel to ONA >









// HALFDONE saccades< think of a way to combine saccades to "high level saccades" which we can use to recognize objects >
//    ISSUE< how do we rank longer saccades for forgetting? >




