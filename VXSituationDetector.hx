import Rng0.CryptoRng0;

// detector for situations
// bases situations on observed classes in the image
class VXSituationDetector {
    // is called when a observation is done, such as every frame
    // /param observedEntityClasses array of id's of classes of objects, doesn't have to be a set!
    public static function observe(entityClasses: Array<Int>,   ctx: VXSituationDetectorContext) {
        // add the observed classes to the accumulator of observed clases for this sitation
        for (iClass in entityClasses) {
            ctx.currentSitutationEntityClassAccumulator.set(iClass, true);
        }
    }

    // /param currentTime: is the current system time - should be close to "real"-time
    public static function finishCurrentSituation(currentTime: Int,   ctx: VXSituationDetectorContext) {
        // accumulate "situation vector" which describes the current situation
        {
            var accSituationVector: Array<Float> = BRealvectorUtils.genZero(ctx.config__vecLength);

            // iterate over currently observed classes and add the HD-vec associated with it to the sitation vector "accSituationVector"
            for (iObservedClassId in ctx.currentSitutationEntityClassAccumulator.keys()) {
                var hdVectorOfThisObservedClass: Array<Float> = helper__retrieveHdVecByClassId(iObservedClassId, currentTime,   ctx);
                accSituationVector = BRealvectorUtils.add(accSituationVector, hdVectorOfThisObservedClass);
            }

            // store vector of current situation
            ctx.currentSituationHdVector = accSituationVector;
        }

        // reset for next frame
        ctx.currentSitutationEntityClassAccumulator.clear();
    }

    
    public static function forceGc(ctx: VXSituationDetectorContext) {
        // do GC of "mapObsClassToHdVec"
        {
            // TODO< implement ME! >
            // use ctx.mapObsClassToHdVec
        }
    }






    // helper to return the associated HD-vector for a given observed class (by id)
    //
    // implementation: takes care of allocating a fresh id if the one requested is not present
    // /param currentTime is the current system time
    public static function helper__retrieveHdVecByClassId(classId: Int, currentTime: Int,   ctx: VXSituationDetectorContext) {
        if (!ctx.mapObsClassToHdVec.exists(classId) ) {
            // * allocate
            var hdVec: Array<Float> = BRealvectorUtils.genRandom(ctx.config__vecLength, ctx.rng);

            // * add
            var createdEntity = new VXSitationDetectorObservedClassEntry(classId, hdVec, currentTime);
            ctx.mapObsClassToHdVec.set(classId, createdEntity);
        }
        
        return ctx.mapObsClassToHdVec[classId].vec;
    }
}

class VXSituationDetectorContext {
    public var config__vecLength: Int; // length of the vector


    //public var situationEntries: AikrGc<VXSituationDetectorEntry>;

    // used to accumulate the classes of the current situation
    public var currentSitutationEntityClassAccumulator: Map<Int, Bool> = new Map<Int, Bool>();

    // HD-vector which describes the current (last) situation
    public var currentSituationHdVector: Array<Float>; // inited with null because there is no "finished" sitation at first!


    // map a observed class to a HD-vector
    public var mapObsClassToHdVec: Map<Int, VXSitationDetectorObservedClassEntry> = new Map<Int, VXSitationDetectorObservedClassEntry>();



    public var rng: Rng0 = new CryptoRng0("0000"); // used Rng

    public function new(config__vecLength) {
        this.config__vecLength = config__vecLength;
    }
}

// entry to bind a observed class to a unique id as a HD-vector
class VXSitationDetectorObservedClassEntry {
    public var timeLastObserved: Int; // when was this the last time observed?
    public var classId: Int;
    public var vec: Array<Float>;

    public function new(classId: Int, vec: Array<Float>, timeLastObserved: Int) {
        this.timeLastObserved = timeLastObserved;
        this.classId = classId;
        this.vec = vec;
    }
}
