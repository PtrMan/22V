// custom implementation of ART-2

import sys.thread.Thread;
import sys.thread.Lock;
import sys.thread.Mutex;

import Rng0;

class MyArt_v1 {
    public var a: Float = 2.0; //10.0; // parameter
    public var b: Float = 1.2; // parameter
    public var c: Float = 0.1; // parameter
    public var d: Float = 0.8; // parameter 0.0 < d < 1.0 // is some kind of learning rate
    

    public var e: Float = 0.01; // parameter
    public var sigma: Float = 0.0; // parameter, used for noise surpression
    public var vigilance: Float = 1.0; // parameter in range 0.0 < x < 1.0

    public var vecWidth: Int = 5; // width of vector // called "N" in paper

    public var roundsLtm: Int = 3; // rounds of LTM

    public var resetAttempts: Int = 5; // how many times is classification tried with reset till give up?

    //public var prototypes: Array<ArtPrototype> = [];
    public var z: Map2dFloat = null; // matrix with weights of supression-matrix and prototypes

    public var M: Int = 10; // number of prototypes

    public var enLearning: Bool = true; // enable learning? - is useful to toggle to pure classification

    public var enDbg: Bool = false;

    // number of worker threads
    public var nThreads: Int = 8;


    public function new() {}

    public function init(rng: Rng0) {
        { // check the ratio between c and d
            var ratio: Float = (c*d) / (1.0-d);
            trace('ratio=$ratio');
            if (ratio >= 1.0) {
                throw new haxe.Exception("ratio violated!");
            }
        }

        { // check 2/3 rule inequality by ART1 paper
            var condA: Bool = Math.max(1.0, d) < b;
            var condB: Bool = b < d + 1.0;
            var cond: Bool = condA&&condB;
            trace('cond=${cond}');
            if (!cond) {
                throw new haxe.Exception("cond violated!");
            }
        }

        z = new Map2dFloat(M+vecWidth,M+vecWidth);

        
        //for(im in 0...M) {
        //    var createdPrototype = new ArtPrototype(vecNull(vecWidth));
        //
        //    /*
        //    // init bottom up weights as described in the paper
        //    var scale: Float = 1.0 / ((1.0 - d)*Math.sqrt(M));
        //    createdPrototype.zBottomUp = [];
        //    for(ii in 0...vecWidth) {
        //        var v: Float = scale*0.1 + rng.genFloat01()*scale*0.1*0.5;
        //        createdPrototype.zBottomUp.push(v);
        //    }*/

        //    // init top down weights (as described in the paper)
        //    var scale: Float = 1.0 / ((1.0 - d)*Math.sqrt(M));
        //    createdPrototype.v = [];
        //    for(ii in 0...vecWidth) {
        //        var v: Float = scale*0.1 + rng.genFloat01()*scale*0.1*0.5;
        //        createdPrototype.v.push(v);
        //    }
        //
        //    prototypes.push(createdPrototype);
        //}


        // init weights (as described in the paper in chapter XI)
        {
            var scale: Float = 1.0 / ((1.0 - d)*Math.sqrt(M));
            for (i in 0...M) {
                for (j in M...M+vecWidth) {
                    var v: Float = rng.genFloat01()*scale; //scale*0.1 + rng.genFloat01()*scale*0.1*0.5;
                    //trace('rng $v');
                    z.writeAtSafe(i,j, v);
                }
            }            
        }
    }

    

    public function applyF(x: Array<Float>): Array<Float> {
        var res = [];
        for (ix in x) {
            var v = ix;
            if (ix < sigma) {
                v = (2.0*sigma*ix*ix) / (ix*ix + sigma*sigma); // nonlinearity
            }
            res.push(v);
        }
        return res;
    }




    public static function vecScale(a: Array<Float>, s: Float): Array<Float> {
        var res: Array<Float> = [];
        for (iv in a) {
            res.push(iv*s);
        }
        return res;
    }

    public static function vecAdd(a: Array<Float>, b: Array<Float>): Array<Float> {
        if (a.length != b.length) {
            //throw Exception("ERR");
        }

        var res: Array<Float> = [];
        for(iidx in 0...a.length) {
            var v: Float = a[iidx]+b[iidx];
            res.push(v);
        }
        return res;
    }
    public static function vecSub(a: Array<Float>, b: Array<Float>): Array<Float> {
        if (a.length != b.length) {
            //throw Exception("ERR");
        }

        var res: Array<Float> = [];
        for(iidx in 0...a.length) {
            var v: Float = a[iidx]-b[iidx];
            res.push(v);
        }
        return res;
    }

    public static function vecNorm2(v: Array<Float>): Float {
        var l = 0.0;
        for(iv in v) {
            l += iv*iv;
        }
        return Math.sqrt(l);
    }

    public static function vecNull(width: Int): Array<Float> {
        var res = [];
        for(i in 0...width) {
            res.push(0.0);
        }
        return res;
    }

    public static function vecDot(a: Array<Float>, b: Array<Float>): Float {
        if (a.length != b.length) {
            //throw Exception("ERR");
        }
        
        var v = 0.0;
        for(iidx in 0...a.length) {
            v += a[iidx]*b[iidx];
        }
        return v;
    }
}

/*
class ArtPrototype {
    public var v: Array<Float>;
    ///public var zBottomUp: Array<Float>; // bottom up weights F1->F2
    public function new(v) {
        this.v = v;
    }
}
*/

// context for art classification
// OPTIMIZATION< is just a optimization to get the implementation which uses JVM as a target up to speed >
class ArtCtx {
    public var art: MyArt_v1;

    private var p: Array<Float> = null;
    private var u: Array<Float> = null;
    private var selIdx: Int = -1; // selected index returned by calc()

    private var entryLocks: Array<Lock> = [];
    private var exitLocks: Array<Lock> = [];

    private var gatherMutex: Mutex;

    private var prototypeIsSurpressed: Array<Bool>; // array to store flags for surpression of prototypes

    private var gather: Array<{winnerPrototypeIdx:Int,winnerPrototypeTj:Float}> = []; // sued for gathering results
    

    public function new(art: MyArt_v1) {
        this.art = art;

        gatherMutex = new Mutex();

        for (iThreadIdx in 0...art.nThreads) {
            entryLocks.push(new Lock());
            exitLocks.push(new Lock());
        }

        for (iThreadIdx in 0...art.nThreads) {
            var t0: Thread = Thread.create(() -> {
                while (true) {
                    workerInner(iThreadIdx);
                    //trace('workerThread idx=$iThreadIdx is done!');
                }
            });
        }
    }


    // encapsulation of inner work for inner thread
    // /param threadIdx index of the thread, is used to uniformly distribute work
    private function workerInner(threadIdx: Int) {
        entryLocks[threadIdx].wait(); // wait here till there is work to do
        
        var winnerPrototypeIdx: Int = -1;
        var winnerPrototypeTj: Float = Math.NEGATIVE_INFINITY;
        
        var iProtoIdx: Int = threadIdx;
        while (iProtoIdx < art.M) {
            var thisIProtoIdx: Int = iProtoIdx;
            iProtoIdx+=art.nThreads;

            //var iPrototype: ArtPrototype = art.prototypes[thisIProtoIdx];

            if (prototypeIsSurpressed[thisIProtoIdx]) {
                continue; // ignore surpressed prototypes for F2 matching!
            }

            var dotRes: Float = 0.0;
            {
                var j: Int = art.M + thisIProtoIdx;
                for (i in 0...p.length) {
                    var zVal: Float = art.z.readAtUnsafe(i,j);
                    dotRes += (p[i]*zVal);
                }
            }

            var Tj: Float = dotRes; //MyArt_v1.vecDot(p, iPrototype.v);///MyArt_v1.vecDot(p, iPrototype.zBottomUp);
            if (Tj > winnerPrototypeTj) {
                winnerPrototypeTj = Tj;
                winnerPrototypeIdx = thisIProtoIdx;
            }
        }

        exitLocks[threadIdx].release(); // send signal that the work was done


        gatherMutex.acquire();
        gather.push({winnerPrototypeIdx:winnerPrototypeIdx,winnerPrototypeTj:winnerPrototypeTj});
        gatherMutex.release();
    }

    public function calc(I: Array<Float>): Int {
        // reset surpression by reset
        prototypeIsSurpressed = [];
        for(idx in 0...art.M) {
            prototypeIsSurpressed.push(false);
        }

        selIdx = -1;
        u = null;

        for (iTry in 0...art.resetAttempts) { // loop over attemps which is reseted by reset mechanism

            selIdx = -1;
            
            var enReset: Bool = false;
    
            for (iOuterRound in 0...2) {
    
                var v: Array<Float> = MyArt_v1.vecNull(art.vecWidth);
                
                //var p: Array<Float> = null;
                p = null;
                
                // # solver for ART STM equations
                for(iRound in 0...art.roundsLtm) {
                    // u_i = v_i / (e + ||v||)             (6)
                    u = MyArt_v1.vecScale(v, 1.0 / (art.e + MyArt_v1.vecNorm2(v)));
                    
                    // p_i = u_i + sum_j ( g(y_i)*z_ji )   (4)
                    p = u; // special case if no category was learned yet!
                    if (selIdx != -1) { // was a candidate selected?
                        // read off of prototype
                        var prototypeVec: Array<Float> = [];
                        {
                            var j: Int = art.M + selIdx;
                            for (i in 0...p.length) {
                                var zVal: Float = art.z.readAtSafe(i,j);
                                prototypeVec.push(zVal);
                            }
                        }
                        //prototypeVec = art.prototypes[selIdx].v;

                        var temp0 = MyArt_v1.vecScale(prototypeVec, art.d);
                        p = MyArt_v1.vecAdd(u, temp0);
                    }
        
                    // q_i = p_i / (e + ||p||)             (5)
                    var q = MyArt_v1.vecScale(p, 1.0 / (art.e + MyArt_v1.vecNorm2(p)));
        
        
                    // w_i = I_i + au_i                    (8)
                    var w = MyArt_v1.vecAdd(I, MyArt_v1.vecScale(u, art.a));
        
                    // x_i = w_i / (e + ||w||)             (9)
                    var x = MyArt_v1.vecScale(w, 1.0 / (art.e + MyArt_v1.vecNorm2(w)));
        
        
                    // v_i = f(x_i) + b f(q_i)             (7)
                    v = MyArt_v1.vecAdd(art.applyF(x), MyArt_v1.vecScale(art.applyF(q), art.b));
                }
        
        
                // # F2 matching
                if (iOuterRound == 0) { // we only match F2 if we didn't find yet a best candidate!
                    // * release all worker threads to do some useful work!
                    for (iThreadIdx in 0...art.nThreads) {
                        entryLocks[iThreadIdx].release();
                    }

                    // * wait for work of all worker threads!
                    for (iThreadIdx in 0...art.nThreads) {
                        exitLocks[iThreadIdx].wait();
                    }
                    
                    // * gather results
                    var winnerPrototypeIdx: Int = -1;
                    var winnerPrototypeTj: Float = Math.NEGATIVE_INFINITY;
                    {
                        //trace('');
                        for (iGather in gather) {
                            //trace('DBG winnerPrototypeIdx=${iGather.winnerPrototypeIdx} Tj=${winnerPrototypeTj}');

                            if (iGather.winnerPrototypeTj > winnerPrototypeTj) {
                                winnerPrototypeIdx = iGather.winnerPrototypeIdx;
                                winnerPrototypeTj = iGather.winnerPrototypeTj;
                            }
                        }
                        gather = []; // flush gather
                    }


                    /* commented because it is the old non-parallel code
                    var winnerPrototypeIdx: Int = -1;
                    var winnerPrototypeTj: Float = Math.NEGATIVE_INFINITY;
                    for(iProtoIdx in 0...prototypes.length) {
                        var iPrototype: ArtPrototype = prototypes[iProtoIdx];
    
                        if (iPrototype.isSurpressed) {
                            continue; // ignore surpressed prototypes for F2 matching!
                        }
    
                        var Tj: Float = vecDot(p, iPrototype.zBottomUp);
                        if (Tj > winnerPrototypeTj) {
                            winnerPrototypeTj = Tj;
                            winnerPrototypeIdx = iProtoIdx;
                        }
                    }
                    */

                    
                    if (art.enDbg) {
                        trace('winner prototype idx=$winnerPrototypeIdx Tj=$winnerPrototypeTj');
                    }
            
                    selIdx = winnerPrototypeIdx;
                }
    
                
        
                if (iOuterRound == 1) {
                    // compute reset
                    //                                 formula (20)
                    var r = MyArt_v1.vecScale(MyArt_v1.vecAdd(u, MyArt_v1.vecScale(p, art.c)), 1.0 / (art.e + MyArt_v1.vecNorm2(u)+MyArt_v1.vecNorm2(MyArt_v1.vecScale(p,art.c))));
            
                    // reset when ever an input pattern is active and when the reset condition is true
                    enReset = art.vigilance / (art.e + MyArt_v1.vecNorm2(r)) > 1.0;
                    if (art.enDbg) {
                        trace('DBG resetVal=${art.vigilance / (art.e + MyArt_v1.vecNorm2(r))}');
                        trace('DBG -> enReset=$enReset');
                    }
                    
                    // reset mechanism which surpresses a prototype if it doesn't fit
                    if (enReset) {
                        prototypeIsSurpressed[selIdx] = true; // surpress by reset
                    }
                }
                
            }

            if (!enReset) {
                break; // we don't need another round if reset is not active!
            }
        }
        
        return selIdx; // we return the classification
    }

    public function calcUpdate() {
        // # LTM
        if (art.enLearning) { // only do if learning is enabled
            //{ // adapt top-down weights F2->F1
            //    var zJ: Array<Float> = art.prototypes[selIdx].v;
            //    
            //    var temp0 = MyArt_v1.vecScale(u, 1.0 / (1.0 - art.d));
            //    temp0 = MyArt_v1.vecSub(temp0, zJ);
            //    var delta = MyArt_v1.vecScale(temp0, art.d*(1.0-art.d)); // compute delta to adjust weights
            //
            //    zJ = MyArt_v1.vecAdd(zJ, delta); // actually update weights
            //    
            //    if (art.enDbg) {
            //        trace('zJ=');
            //        for(iv in zJ) {
            //           trace('   $iv');
            //        }
            //    }
            //
            //    art.prototypes[selIdx].v = zJ; // update prototype
            //}


            /* commented because there are no different weights for bottom-up F1->F2
            { // adapt bottom-up weights F1->F2
                var ziJ: Array<Float> = art.prototypes[selIdx].zBottomUp;
                var temp0 = MyArt_v1.vecScale(u, 1.0 / (1.0 - art.d));
                temp0 = MyArt_v1.vecSub(temp0, ziJ);
                var delta = MyArt_v1.vecScale(temp0, art.d*(1.0-art.d)); // compute delta to adjust weights
    
                ziJ = MyArt_v1.vecAdd(ziJ, delta); // actually update weights
                
                if (art.enDbg) {
                    trace('ziJ=');
                    for(iv in ziJ) {
                        trace('   $iv');
                    }
                }
                
                art.prototypes[selIdx].zBottomUp = ziJ; // update prototype
            }
            */
        }

        if (art.enLearning) { // only do if learning is enabled
            { // adapt weights top-down
                var factor: Float = art.d*(1.0-art.d);

                for (i in 0...u.length) {
                    var J: Int = selIdx; // Jth node is active
                    
                    if (i == J) // commented because ME is not sure about this
                    {
                        var delta: Float = factor*(u[i]/(1.0-art.d) - art.z.readAtSafe(J,i));
                        var val: Float = art.z.readAtSafe(J,i) + delta;
                        art.z.writeAtSafe(J,i, val);
                    }
                }
            }

            { // adapt weights bottom-up
                var factor: Float = art.d*(1.0-art.d);

                for (i in 0...u.length) {
                    var J: Int = art.M + selIdx; // Jth node is active
                    
                    //if (i == J) // commented because ME is not sure about this
                    {
                        var delta: Float = factor*(u[i]/(1.0-art.d) - art.z.readAtSafe(i,J));
                        var val: Float = art.z.readAtSafe(i,J) + delta;
                        art.z.writeAtSafe(i,J, val);
                    }
                }
            }
        }

        return selIdx; // we return the classification
    }
}
