// implementation of classifier for proto-objects based on a set of discrete items

import ProtoobjectClassifierCircuit;

// classifier to compute proto objects from stimulus
class ProtoobjectClassifier {
    public static function classify(stimulusItems: Array<{pos:{x:Float,y:Float},id:Int}>,  ctx: ProtoobjectClassifierCtx) {
        var stimulusAsHdVec: Array<Float> = ProtoobjectClassifierCircuit.calcHdVecOfSet(stimulusItems,  ctx.circuitCtx);
        trace('DBG: ProtoobjectClassifier.classify(): stimulusVec=$stimulusAsHdVec');

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
                // add evidence
                bestItem.hdVec = BRealvectorUtils.add(bestItem.hdVec, stimulusAsHdVec);
                
                // FIXME< ensure that this doesn't wrap around! >
                bestItem.evidenceCount++;
            }

            return bestItem;
        }
        else {
            // else we add it as new prototype
            var createdItem: ProtoobjectClassifierItem = new ProtoobjectClassifierItem(stimulusAsHdVec, ctx.prototypeIdCounter++);
            ctx.items.push(createdItem);
            return createdItem;
        }
    }
}

class ProtoobjectClassifierCtx {
    // parameters
    public var thresholdCreateNewPrototype: Float = -1.0; // threshold of similarity to known prototypes to create new prototypes

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

    public function new(hdVec:Array<Float>, id) {
        this.hdVec = hdVec;
        this.id = id;
    }
}

// TODO< add AIKR GC >
