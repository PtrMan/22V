// low level bitvector manipulation

import Rng0;
import g.ArrUtils;
import BRealvectorUtils;

class BBitvectorUtils {
    public static function or(a: Array<Bool>, b: Array<Bool>): Array<Bool> {
        var res = [];
        for(i in 0...a.length) {
            res.push(a[i] || b[i]);
        }
        return res;
    }

    public static function xor(a: Array<Bool>, b: Array<Bool>): Array<Bool> {
        var res = [];
        for(i in 0...a.length) {
            res.push(a[i] != b[i]);
        }
        return res;
    }

    //& permutation
    public static function perm(a: Array<Bool>, perm: Array<Int>): Array<Bool> {
        var res = [];
        for(i in 0...a.length) {
            var iiidx: Int = perm[i];
            res.push(a[iiidx]);
        }
        return res;
    }

    // create a random permutation
    public static function genPerm(len: Int,  rng: Rng0): Array<Int> {
        var res = [];

        var remaining = [];
        for(i in 0...len) {
            remaining.push(i);
        }

        while(remaining.length > 0) {
            var idx = rng.genInt(remaining.length);
            var val = remaining[idx];
            remaining = new ArrUtils<Int>().removeAt(remaining, idx);
            res.push(val);
        }

        return res;
    }

    //& normalized manhattan distance
    public static function distManhatanNorm(a: Array<Bool>, b: Array<Bool>): Float {
        var d: Float = distManhantan(a,b);
        return d / a.length;
    }

    public static function distManhantan(a: Array<Bool>, b: Array<Bool>): Int {
        var res = 0;
        for(i in 0...a.length) {
            res += (a[i] != b[i] ? 1 : 0);
        }
        return res;
    }

    //& generate vector with n random set bits
    public static function genRandomVec(len: Int, n: Int, rng: Rng0): Array<Bool> {
        var v0: Array<Bool> = [];
        for(a in 0...len) {
            v0.push(false);
        }

        // init with random vector
        for(b in 0...n) {
            var idx:Int = rng.genInt(v0.length);
            v0[idx] = true;
        }

        return v0;
    }





    // converts a real value to a boolean vec
    // /param val value to get converted, must be in range [0.0;1.0]
    public static function convRealValue01ToBoolVec(val:Float, len:Int, width:Int): Array<Bool> {
        var v0: Array<Bool> = [];
        for(a in 0...len) {
            v0.push(false);
        }

        var centerIdx: Int = Std.int(val * len); // compute index of center of ""

        for(iIdx in centerIdx-Std.int(width/2)...centerIdx+Std.int(width/2)) {
            if (iIdx >= 0 && iIdx < len) {
                v0[iIdx] = true;
            }
        }

        return v0;
    }



    // untested!
    //& computes the "sum" by middle of the sum of the vector
    //& see paper "Hyperdimensional Computing: An Introduction to Computing in Distributed Representation with High-Dimensional Random Vectors"
    //&&
    //& can be used to "mix" vector with a ratio of 1:1 !!!
    public static function add(a:Array<Bool>, b:Array<Bool>): Array<Bool> {
        var ar:Array<Float> = convToReal(a);
        var br:Array<Float> = convToReal(b);
        var vr:Array<Float> = BRealvectorUtils.add(ar,br);
        var len:Float = BRealvectorUtils.len(vr);
        var rr:Array<Float> = BRealvectorUtils.scale(vr, 1.0/len); // normalize
        var r:Array<Bool> = convToBoolVec(rr);
        return r;
    }
    
    //& helper
    public static function convToReal(v:Array<Bool>): Array<Float> {
        var res=[];
        for(iv in v) {
            res.push(iv ? 1.0 : -1.0); // to real vector as described by Kaverna
        }
        return res;
    }

    //& helper
    public static function convToBoolVec(v:Array<Float>): Array<Bool> {
        var res=[];
        for(iv in v) {
            res.push(iv > 0.0);
        }
        return res;
    }
}
