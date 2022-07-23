import MathUtils2;

class BRealvectorUtils {
    public static function add(a:Array<Float>,b:Array<Float>):Array<Float> {
        var res=[];
        for(idx in 0...a.length) {
            res.push(a[idx]+b[idx]);
        }
        return res;
    }

    public static function sub(a:Array<Float>,b:Array<Float>):Array<Float> {
        var res=[];
        for(idx in 0...a.length) {
            res.push(a[idx]-b[idx]);
        }
        return res;
    }

    //& component wise multiplication
    public static function mul(a:Array<Float>,b:Array<Float>):Array<Float> {
        var res=[];
        for(idx in 0...a.length) {
            res.push(a[idx]*b[idx]);
        }
        return res;
    }

    //& helper
    public static function len(v:Array<Float>): Float {
        var len:Float = 0.0;
        for(iv in v) {
            len += (iv*iv);
        }
        return Math.sqrt(len);
    }

    //& helper
    public static function dist(a:Array<Float>, b:Array<Float>): Float {
        return len(sub(a,b));
    }

    // cosine-similarity
    public static function calcCosineSim(a:Array<Float>, b:Array<Float>): Float {
        // see https://en.wikipedia.org/wiki/Cosine_similarity
        return dot(a,b) / (len(a)*len(b));
    }

    public static function dot(a:Array<Float>, b:Array<Float>): Float {
        var res=0.0;
        for(i in 0...a.length) {
            res += a[i]*b[i];
        }
        return res;
    }

    //& helper
    public static function scale(v:Array<Float>, s:Float): Array<Float> {
        var res=[];
        for(iv in v) {
            res.push(iv*s);
        }
        return res;
    }

    //& normalize into to [0.0;1.0] range
    public static function normalize(v:Array<Float>): Array<Float> {
        var minVal: Float = Math.POSITIVE_INFINITY;
        var maxVal: Float = Math.NEGATIVE_INFINITY;

        for(iv in v) {
            minVal = Math.min(minVal, iv);
            maxVal = Math.max(maxVal, iv);
        }

        var res:Array<Float> = [];
        for(iv in v) {
            // map to [0.0;1.0] range
            var remappedIv:Float = MathUtils2.convTo01Range(iv, minVal, maxVal);
            res.push(remappedIv);
        }
        return res;
    }

    //& permutation
    public static function perm(a: Array<Float>, perm: Array<Int>): Array<Float> {
        var res = [];
        for(i in 0...a.length) {
            var iiidx: Int = perm[i];
            res.push(a[iiidx]);
        }
        return res;
    }

    //& generate random vector
    public static function genRandom(len:Int, rng: Rng0) {
        var vec:Array<Float> = [];
        for(i in 0...len) {
            var val:Float = rng.genFloat01()*2.0 - 1.0;
            vec.push(val);
        }
        return vec;
    }

    public static function genZero(len:Int) {
        var vec:Array<Float> = [];
        for(i in 0...len) {
            vec.push(0.0);
        }
        return vec;
    }

    //& compute the probability that two random vectors occur within the given distance
    // TODO< is wrong because the forumla has to use the gamma function! >
    public static function calcProb(vecWidth:Int, dist:Float): Float {

        //ME< I derived the formula myself but it gives results which make sense to me >

        //dist = 1.3 # measured euclidian distance between two vectors
        //vecWidth = 1024*6

        // first we need to calculate the difference in each dimension:
        // dist = sqrt(a^2 * vecWidth)
        // dist^2 = a^2 * vecWidth
        // dist^2 / vecWidth = a^2
        // sqrt(dist^2 / vecWidth) = a

        var a:Float = Math.sqrt((dist*dist)/vecWidth);

        //print(a)

        // now we compute the probability that it is in the [-1;1] interval in each dimension by chance:
        var propPerDim:Float = a/2.0; // propability that it is in one dimension:
        var prop:Float = Math.pow(1.0-propPerDim, vecWidth);

        return prop;
    }



    // converts a real value to a real vec
    // /param val value to get converted, must be in range [0.0;1.0]
    public static function convRealValue01ToVec(val:Float, len:Int, width:Float): Array<Float> {
        var v0: Array<Float> = [];

        var center: Float = val * len; // compute real valued index of center
        for (iIdx in 0...len) {
            var iPosAbs: Float = iIdx + 0.5; // compute absolute center position
            
            var dist: Float = Math.abs(center-iPosAbs);

            var valAtThisIndex: Float = width/2 - dist; // compute "height" value at this index
            // clamp it
            valAtThisIndex = Math.max(valAtThisIndex, 0.0);
            valAtThisIndex = Math.min(valAtThisIndex, 1.0);
            
            v0[iIdx] = valAtThisIndex;
        }

        return v0;
    }
}
