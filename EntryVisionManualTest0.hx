import sys.io.File;

import Rng0.CryptoRng0;
import PROTOVis2;
import PROTOExportLatex;
import ProtoobjectClassifier;

import PROTOExternalClassThingy0; // for testing


// run with
//    haxe --jvm a.jar  EntryVisionManualTest0.hx --main EntryVisionManualTest0.hx && java -jar ./a.jar consoleIo0

//    TERDZIMG     haxe --jvm a.jar  EntryVisionManualTest0.hx --java-lib l.jar --main EntryVisionManualTest0.hx && java -classpath ./l.jar -jar a.jar -jar l.jar consoleIo0
//                 haxe --jvm a.jar  EntryVisionManualTest0.hx --java-lib l.jar --main EntryVisionManualTest0.hx && java -server -jar a.jar consoleIo0

class EntryVisionManualTest0 {
    public static function main() {
        // testing external java
        ExtA.f0(0.1, 1.2);
        ExtA.createAndInitWindow();
        ExtA.update("b 10 20 30 45"); // for testing


        // name of the "entry" program to jump to
        //var chosenEntryname: String = "manualTest0";
        //chosenEntryname = "consoleIo0";
        var chosenEntryname: String = Sys.args()[0];

        if (chosenEntryname == "manualTestDevRunner0") {
            
            ProgramRunnerMotion.run("./dataset.test.images.1/pexels-mathias-reding-12624892.ppm", "./dataset.test.images.1/pexels-mathias-reding-12624892.ppm");

            Sys.println("DONE");

        }
        else if (chosenEntryname == "manualTest0") {
            
            var ctx: Vis2Ctx = new Vis2Ctx();
            PROTOVis2.defaultInit(ctx);

            // load image from source
            ctx.img = PpmReader.readPpm("./dataset.test.images.1/peppers.ppm");
            PROTOVis2.notifyImageUpdated(ctx);

            var outerLoopIteration: Int = 0;
            while(true) {
                if (outerLoopIteration >= 2000) { // break out for prototyping
                    break;
                }
                
                outerLoopIteration++;




                if (true) { // load image from file?
                    if (outerLoopIteration == 1000) {
                        // load image from source
                        ctx.img = PpmReader.readPpm("./dataset.test.images.1/trees1a.ppm");
                        PROTOVis2.notifyImageUpdated(ctx);
                    }
                }


                // TESTING< paint different images to see how it classifies etc. >
                if (false) {
                    if (outerLoopIteration == 1) {
                        ctx.img = new Map2dRgb(32,32);
                        // paint a white box for testing
                        Map2dRgbDraw.drawBox(ctx.img, 16-4, 16-4, 16+4, 16+4, new Map2dRgb.Rgb(1.0,1.0,1.0));
                    }
                    /*
                    else if (outerLoopIteration == 2) {
                        ctx.img = new Map2dRgb(32,32);
                        // paint a white box for testing
                        Map2dRgbDraw.drawBox(ctx.img, 16, 16, 16+8, 16+8, new Map2dRgb.Rgb(0.1,0.1,0.1));
                    }
                    */
                    else if (outerLoopIteration == 4) {
                        ctx.img = new Map2dRgb(32,32);
                        // paint a white box for testing
                        Map2dRgbDraw.drawBox(ctx.img, 16, 16, 16+8, 16+8, new Map2dRgb.Rgb(1.0,1.0,1.0));
                    }    
                }
                
                PROTOVis2.doCycle(ctx);
            }
        }
        else if (chosenEntryname == "consoleIo0") { // program which reads commands from the console and executes them, maybe useful for scripting and connecting it to a reasoner without the use of networking
            
            var ctx: Vis2Ctx = new Vis2Ctx();
            PROTOVis2.defaultInit(ctx);

            // CHANGED PARAMETER
            var enGenLatexReport: Bool = false; // generate a latex report file?


            var latexSinkCtx: ExportLatexCtx = null;

            if (enGenLatexReport) {
                latexSinkCtx = new ExportLatexCtx();
                ctx.sinkEyeSaccades = new SinkEyeSaccadesLatexTikz(latexSinkCtx, ctx); // set the reporter to the reporter to record eye saccades and draw them to the document as a image
            
                ctx.sinkProtoobjects = new SinkProtoobjectsLatexTikz(latexSinkCtx, ctx);
            }

            function _helper() {
                // testing
                //execCmd("!readf ./dataset.test.images.1/pexels-mathias-reding-12624892.ppm", ctx);
                //execCmd("!s 5", ctx);
                //execCmd("!s 100", ctx);
                //return;


                {
                    var usedRng: Rng0 = new CryptoRng0("vision");
                    

                    if (latexSinkCtx != null) {
                        PROTOExportLatex.emitDocumentIntro(latexSinkCtx);
                    }


                    // loop to see if it stabilizes
                    for(iIt in 0...150) {
                        var filename: Array<String> = ["pexels-mathias-reding-12624892.ppm", "trees1a.ppm", "peppers.ppm", "ice_flow.ppm"];
                        var selIdx: Int = usedRng.genInt(filename.length);
                        var selFilename: String = filename[selIdx];
    
                        execCmd('!readf ./dataset.test.images.1/$selFilename', ctx);
                        
                        PROTOVis2.startFrame(ctx); // send message that a new frame was presented
                        
                        // each debugging visualization displays a few paths
                        //
                        // we do this this way because else it's to confusing for a human to debug visually
                        for(iSubrun in 0...50) {
                            
                            if (latexSinkCtx != null) {
                                PROTOExportLatex.emitTikzPreamble(latexSinkCtx);
                            }
                            
                            //execCmd("!s 2500", ctx);
                            execCmd("!s 45", ctx);
    
                            if (latexSinkCtx != null) {
                                PROTOExportLatex.emitTikzPostamble(latexSinkCtx);
                            }
                        }

                        PROTOVis2.endFrame(ctx); // send message that the processing of the frame is done, so it can do work when the frame is completed
                    }


                    if (latexSinkCtx != null) {
                        PROTOExportLatex.emitDocumentOuttro(latexSinkCtx);

                        // write to report output file
                        File.saveContent("./reportA0.tex", latexSinkCtx.buffer);
                    }
                }
                
                return;



                // TESTING< we feed it commands for faster testing >
                {
                    execCmd("!readf ./dataset.test.images.1/pexels-mathias-reding-12624892.ppm", ctx);
                    //execCmd("!s 5", ctx);
                    execCmd("!s 2500", ctx);
                    
                    execCmd("!readf ./dataset.test.images.1/trees1a.ppm", ctx);
                    execCmd("!s 2500", ctx);
                }


                return; // force exit of program



                while (true) { // command loop
                    var commandString: String = Sys.stdin().readLine();
                    Sys.println('CMD=${commandString}');

                    var execResCode: Int = execCmd(commandString, ctx);
                    if (execResCode == 1) {
                        return; // break out of loop to terminate program
                    }
                }
            }

            _helper();


            // helper to print a console report with a summary to the console
            function printConsoleReport() {
                Sys.print('\n\n\n');
                Sys.println('final REPORT:');
                Sys.println('nSaccades=${ctx.saccadeSet.length}'); // how many eye saccades are in the system?
                Sys.print('\n');
                Sys.println('protoobjects.nPrototypes=${ctx.prototypeClassifierCtx.items.length}');
            }

            printConsoleReport();
        }
        else if (chosenEntryname == "camera0") {

            var ctx: Vis2Ctx = new Vis2Ctx();
            PROTOVis2.defaultInit(ctx);

            while (true) {
                // grab image from camera and convert
                ExecProgramsUtils.grab();
                ExecProgramsUtils.convertGrabbedImage();


                //ctx.imgFrameBefore = ctx.img;
                // load image from source
                ctx.img = PpmReader.readPpm("./outCurrentFrameFromCamera.ppm");
                PROTOVis2.notifyImageUpdated(ctx);



                PROTOVis2.startFrame(ctx); // send message that a new frame was presented

                


                for(iSubrun in 0...50) {
                    execCmd("!s 45", ctx);
                }

                PROTOVis2.endFrame(ctx); // send message that the processing of the frame is done, so it can do work when the frame is completed
            }
        }
        else {
            Sys.println("FATAL ERROR: unknown selected entry!");
        }
    }

    // helper to execute a command
    // /return code to execute from outside loop
    public static function execCmd(commandString: String,  ctx: Vis2Ctx): Int {
        if (commandString.length >= 7 && commandString.substr(0, 7) == "!readf ") { // read image file
            var filenameToload: String = commandString.substr(7);

            // load image from source
            ctx.img = PpmReader.readPpm(filenameToload);
            PROTOVis2.notifyImageUpdated(ctx); // we need to notify perception system that image was changed
        }
        else if (commandString.length >= 3 && commandString.substr(0, 3) == "!s ") { // do n inference steps
            var stepcountStr: String = commandString.substr(3);

            // convert to int
            var stepcountOpt: Null<Int> = Std.parseInt(stepcountStr);

            for(iStep in 0...stepcountOpt) {
                PROTOVis2.doCycle(ctx);
            }
        }
        else if (commandString.length >= 3 && commandString.substr(0, 3) == "!qq") { // force termination
            return 1; // return code to exit program
        }
        else {
            // soft error: unknown command, ignore
        }
        return 0; // return default code to continue
    }
}



// sink for eye saccade
class SinkEyeSaccadesLatexTikz implements SinkEyeSaccades {
    public var latexSinkCtx: ExportLatexCtx;
    public var visionCtx: Vis2Ctx;
    
    public function new(latexSinkCtx, visionCtx) {
        this.latexSinkCtx = latexSinkCtx;
        this.visionCtx = visionCtx;
    }

    public function reportEyeSaccadePath(path:Array<{x:Int,y:Int,class_:Int}>) {
        var tikzLinepath: Array<{x:Float,y:Float}> = [];


        // * draw linepath
        for (iVertex in path) {
            // map image coordinates to latex friendly coordinates
            var x: Float = iVertex.x*(14.0/visionCtx.img.w);
            var y: Float = iVertex.y*(8.0/visionCtx.img.h);

            tikzLinepath.push({x:x,y:y});
        }
        PROTOExportLatex.emitTikzLinePath(tikzLinepath,  latexSinkCtx);


        // * draw text of classes of vertices of classifier
        for (iVertex in path) {
            // map image coordinates to latex friendly coordinates
            var x: Float = iVertex.x*(14.0/visionCtx.img.w);
            var y: Float = iVertex.y*(8.0/visionCtx.img.h);

            PROTOExportLatex.emitTikzTextnode('${iVertex.class_}',{x:x,y:y},  latexSinkCtx);
        }
    }
}





// sink for detected protoobjects of frame

class SinkProtoobjectsLatexTikz implements SinkProtoobjects {
    public var latexSinkCtx: ExportLatexCtx;
    public var visionCtx: Vis2Ctx;

    public function new(latexSinkCtx, visionCtx) {
        this.latexSinkCtx = latexSinkCtx;
        this.visionCtx = visionCtx;
    }

    public function reportProtoobjectsOfFrame(objs:Array<{center:{x:Int,y:Int},protoobj:ProtoobjectClassifierItem}>) {
        // we put it into Tik graph
        PROTOExportLatex.emitTikzPreamble(latexSinkCtx);



        // fill with graph of the protoobjects detecte in this frame
        for (iObj in objs) {
            // map image coordinates to latex friendly coordinates
            var x: Float = iObj.center.x*(14.0/visionCtx.img.w);
            var y: Float = iObj.center.y*(8.0/visionCtx.img.h);

            PROTOExportLatex.emitTikzTextnode('${iObj.protoobj.id}',{x:x,y:y},  latexSinkCtx);
        }




        PROTOExportLatex.emitTikzPostamble(latexSinkCtx);
    }
}
