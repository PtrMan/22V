// implementation of classifier for proto-objects based on a set of discrete items

import ProtoobjectClassifierCircuit;
import MathUtils2;

// classifier to compute proto objects from stimulus
class ProtoobjectClassifier {
    // FIXME< "globalTime" should be a Int64! >
    public static function classify(stimulusItems: Array<{pos:{x:Float,y:Float},id:Int}>,  globalTime: Int, ctx: ProtoobjectClassifierCtx) {
        var stimulusAsHdVec: Array<Float> = ProtoobjectClassifierCircuit.calcHdVecOfSet(stimulusItems,  ctx.circuitCtx);
        //trace('DBG: ProtoobjectClassifier.classify(): stimulusVec=$stimulusAsHdVec');

        // * lookup for item in memory which is similar
        var bestItem: ProtoobjectClassifierItem = null;
        var bestItemSim: Float = -1.0;
        for (iItem in ctx.items) {
            var averagedVec: Array<Float> = BRealvectorUtils.scale(iItem.hdVec, 1.0/iItem.evidenceCount); // compute average of evidence

            var iItemSim: Float = BRealvectorUtils.calcCosineSim(stimulusAsHdVec, averagedVec);
            if (iItemSim > bestItemSim) {
                bestItem = iItem;
                bestItemSim = iItemSim;
            }
        }

        if (bestItem != null && bestItemSim >= ctx.thresholdCreateNewPrototype) {
            // do revision
            if (ctx.enRevision) {
                bestItem.timeLastUsed = globalTime;

                // add evidence
                bestItem.hdVec = BRealvectorUtils.add(bestItem.hdVec, stimulusAsHdVec);
                
                bestItem.evidenceCount++;
                bestItem.evidenceCount = MathUtils2.minInt(bestItem.evidenceCount, 1 << 30); // ensure this doesn't wrap around!
            }

            return bestItem;
        }
        else {
            // else we add it as new prototype
            var createdItem: ProtoobjectClassifierItem = new ProtoobjectClassifierItem(stimulusAsHdVec, ctx.prototypeIdCounter++, globalTime);
            ctx.items.push(createdItem);
            return createdItem;
        }
    }





    // used to keep memory under AIK
    // this has to be called from time to time by the main-loop
    public static function gc(globalTime: Int, ctx: ProtoobjectClassifierCtx) {
        var inplace: Array<ProtoobjectClassifierItem> = ctx.items.copy();

        // * sort by usefulness
        // TODO< better sorting criterion! >
        inplace.sort((a, b) -> MathUtils2.sign(  Math.exp(-0.08*(globalTime - b.timeLastUsed)) - Math.exp(-0.08*(globalTime - a.timeLastUsed))  ));

        // DBG
        //for(iv in inplace) {
        //    trace(iv.timeLastUsed);
        //}

        var inplaceKeep: Array<ProtoobjectClassifierItem> = inplace.slice(0, ctx.param__nMaxProtoobjects);

        trace('GC lenbefore=${ctx.items.length}');
        ctx.items = inplaceKeep; // keep under AIK
        trace('GC lenafter=${ctx.items.length}');
    }
}

class ProtoobjectClassifierCtx {
    // parameters
    public var thresholdCreateNewPrototype: Float = -1.0; // threshold of similarity to known prototypes to create new prototypes
    public var param__nMaxProtoobjects: Int = 100; // how many protoobjects to store?

    // REFACTORME< should be Int64! >
    public var prototypeIdCounter: Int = 1; // counter to give unique id's to prototypes

    public var circuitCtx: ProtoobjectClassifierCircuitCtx;

    public var items: Array<ProtoobjectClassifierItem> = []; // items which are the remembered protoobjects

    public var enRevision: Bool = true; // enable revision?

    public function new(vecLen:Int,  gridElementsPerDimension:Int) {
        circuitCtx = new ProtoobjectClassifierCircuitCtx(vecLen, gridElementsPerDimension);
    }
}


// prototype which is remembered
class ProtoobjectClassifierItem {
    public var hdVec: Array<Float>;
    public var id: Int; // unique id of the prototype
    public var evidenceCount: Int = 1; // how much evidence was collected?

    public var timeLastUsed: Int;

    public function new(hdVec:Array<Float>, id, creationTime) {
        this.hdVec = hdVec;
        this.id = id;
        this.timeLastUsed = creationTime;
    }
}
