import Rng0.CryptoRng0;
import HdAlgebraUtils;


// "circuit" to compute a vector representing the items so that we can easily compute similarity between proto-objects
class ProtoobjectClassifierCircuit {
    
    // position has range [-1.0;1.0]
    public static function calcHdVecOfSet(items:Array<{pos:{x:Float,y:Float},id:Int}>,  ctx:ProtoobjectClassifierCircuitCtx): Array<Float> {
        var resHdVec: Array<Float> = BRealvectorUtils.genZero(ctx.vecLen);

        for (iItem in items) {
            var remappedX: Float = MathUtils2.convTo01Range(iItem.pos.x, -1.0, 1.0);
            var remappedY: Float = MathUtils2.convTo01Range(iItem.pos.y, -1.0, 1.0);
            var remappedXInt: Int = Std.int(remappedX*ctx.gridElementsPerDimension);
            var remappedYInt: Int = Std.int(remappedY*ctx.gridElementsPerDimension);
            
            var idx: Null<Int> = ctx.calcIdxInMap({x:remappedXInt,y:remappedYInt});
            if (idx != null) { // ignore items which are outside of the valid range!
                var thisHdVec: Array<Float> = BRealvectorUtils.genZero(ctx.vecLen); // hd-vector representing the representation of this "item"


                var selVar: Array<Float> = // HD-vector which is the variable for the respective spatial position
                    ctx.map0vars[idx];
                

                // lookup Hd-Vec coresponding to the id if the item
                var hdVecId: Array<Float> = ctx.idLookupTable.get(iItem.id);

                // bind id
                {
                    var b = HdAlgebraUtils.varBind(hdVecId, ctx.varId);
                    thisHdVec = BRealvectorUtils.add(thisHdVec, b);
                }

                // compute and bind x position
                {
                    var c = BRealvectorUtils.convRealValue01ToVec(remappedXInt, ctx.vecLen, Std.int(ctx.vecLen/10));
                    var b = HdAlgebraUtils.varBind(c, ctx.varX);
                    thisHdVec = BRealvectorUtils.add(thisHdVec, b);
                }

                // compute and bind y position
                {
                    var c = BRealvectorUtils.convRealValue01ToVec(remappedYInt, ctx.vecLen, Std.int(ctx.vecLen/10));
                    var b = HdAlgebraUtils.varBind(c, ctx.varY);
                    thisHdVec = BRealvectorUtils.add(thisHdVec, b);
                }
                
                var a = HdAlgebraUtils.varBind(thisHdVec, selVar);
                resHdVec = BRealvectorUtils.add(resHdVec, a); // add to vector because the result vector is a set!
            }
        }

        //trace('resHdVec=$resHdVec'); // DBG

        return resHdVec;
    }
}

class ProtoobjectClassifierCircuitCtx {
    // we need a map for variables for the grid to differentiate between different spatial locations
    public var map0vars: Array<  Array<Float>   >; // array of HD-vector variables which represent the spatial position, used to disambiguate strngly between 
    public var gridElementsPerDimension:Int; // specifies how many elements fit into each dimension, grid is made of "gridElementsPerDimension"*"gridElementsPerDimension" items
    
    public var vecLen: Int; // length of HD-vectors

    // lookup-table to lookup a unique HD-vector by id
    public var idLookupTable:Map<Int,Array<Float>> = new Map<Int,Array<Float>>();

    // vectors of variables for x, y and id
    public var varX: Array<Float>;
    public var varY: Array<Float>;
    public var varId: Array<Float>;

    // /param vecLen length of hyperdimensional vectors
    public function new(vecLen:Int,  gridElementsPerDimension:Int) {
        this.vecLen = vecLen;
        this.gridElementsPerDimension = gridElementsPerDimension;

        // * create map of vectors to encode spatial position
        var rng: Rng0 = new CryptoRng0("043");
        map0vars = [];
        for(z in 0...gridElementsPerDimension*gridElementsPerDimension) {
            map0vars.push(HdAlgebraUtils.createVar(vecLen, rng));
        }

        varX = HdAlgebraUtils.createVar(vecLen, rng);
        varY = HdAlgebraUtils.createVar(vecLen, rng);
        varId = HdAlgebraUtils.createVar(vecLen, rng);
    }

    //helper
    public function calcIdxInMap(pos:{x:Int,y:Int}): Null<Int> {
        if (pos.x<0||pos.y<0||pos.x>=gridElementsPerDimension||pos.y>=gridElementsPerDimension) {
            return null;
        }
        return pos.x + pos.y*gridElementsPerDimension;
    }
}
