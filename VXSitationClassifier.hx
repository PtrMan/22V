
// algorithm to catalog various situations by a HD-vector of that situation
class VXSitationClassifier {
    // /param hdVector 
    // /return "isNovel" is the situation novel because the novelity is above the novelity-threshold "novelityThreshold"
    //         "recognizedSituationId" id of the recognized situation (or new sitation)
    //         "bestHitSim" highest similarity to all existing sitations
    public static function observeSituation(observedHdVector: Array<Float>, currentTime: Int,   ctx: VXSitationClassifierCtx)
        :{isNovel:Bool, recognizedSituationId: Int, bestHitSim: Float}
    {
        var bestHitSim = -2.0;
        var bestHitEntity: VXSituationClassifierEntry = null;

        for (iSituation in ctx.situationEntries.arr) {
            var sim: Float = BRealvectorUtils.calcCosineSim(observedHdVector, iSituation.hdVector);
            if (sim > bestHitSim) {
                bestHitSim = sim;
                bestHitEntity = iSituation;
            }
        }

        var situationNovelity: Float = -bestHitSim; // novelity of the situation described by "observedHdVector"

        // check if situation is not recognized (because it is completely novel)
        var isNovel: Bool = situationNovelity > ctx.setting__novelityThreshold;

        if (isNovel) {
            // create a new situation and store it
            var createdSituation = new VXSituationClassifierEntry(observedHdVector, ctx.sitationIdCounter++, currentTime);
            ctx.situationEntries.push(createdSituation);

            return {isNovel:isNovel, recognizedSituationId:createdSituation.id, bestHitSim:-1.0};
        }
        else {
            return {isNovel:isNovel, recognizedSituationId:bestHitEntity.id, bestHitSim:bestHitSim};
        }
    }

    public static function forceGc(ctx: VXSitationClassifierCtx) {
        ctx.situationEntries.gc();
    }
}

class VXSitationClassifierCtx {
    // threshold of situation to recognize it as a novel situation
    public var setting__novelityThreshold: Float = 0.75;


    public var situationEntries: AikrGc<VXSituationClassifierEntry>;


    public var sitationIdCounter: Int = 1;

    public function new(nEntriesMax: Int) {
        function sortFn(a: VXSituationClassifierEntry, b: VXSituationClassifierEntry): Int {
            return 0;
        }

        situationEntries = new AikrGc<VXSituationClassifierEntry>(nEntriesMax, sortFn);
    }
}



class VXSituationClassifierEntry {
    public var hdVector: Array<Float>; // HD-vector which describes this situation

    public var id: Int; // id of this situation

    public var timeLastRecognized: Int; // time when it was last recognized in a scene

    public function new(hdVector, id, timeLastRecognized) {
        this.hdVector = hdVector;
        this.id = id;
        this.timeLastRecognized = timeLastRecognized;
    }
}
