import sys.io.Process;

// program runner to detect motion
class ProgramRunnerMotion {
    public static function run(imgAFilename: String, imgBFilename: String):  {mapMag:Map2dFloat, mapAngle:Map2dFloat} {
        // * run python program to compute motion vectors
        var p: Process = new Process('python3 ././pyUtils/CalcOpticalFlow0.py $imgAFilename $imgBFilename > tempFlowTxt.txt');
        p.exitCode(); // wait till the termination of the program

        // * read generated file etc.
        var fileContent: String = sys.io.File.getContent("./tempFlowTxt.txt");

        var lines: Array<String> = fileContent.split('\n');
        

        var dims: {x:Int,y:Int};
        { // parse dimensions
            var dimLine: String = lines[0];
            var dimLineSplited: Array<String> = dimLine.split(" ");
            dims = {x:Std.parseInt(dimLineSplited[0]),y:Std.parseInt(dimLineSplited[1])};
        }

        var outMapMag: Map2dFloat = new Map2dFloat(dims.x, dims.y);
        var outMapAngle: Map2dFloat = new Map2dFloat(dims.x, dims.y);


        // * read values of image from text
        var iCurrentLine: Int = 1;
        for(j in 0...dims.y) {
            for(i in 0...dims.x) {
                var iLine: String = lines[iCurrentLine++];

                var valAsStr: String = iLine.split("=")[1];
                var val: Float = Std.parseFloat(valAsStr);

                outMapMag.writeAtSafe(j,i,val);
            }
        }

        for(j in 0...dims.y) {
            for(i in 0...dims.x) {
                var iLine: String = lines[iCurrentLine++];

                var valAsStr: String = iLine.split("=")[1];
                var val: Float = Std.parseFloat(valAsStr);

                outMapAngle.writeAtSafe(j,i,val);
            }
        }

        return {mapMag:outMapMag, mapAngle:outMapAngle};
    }
}
