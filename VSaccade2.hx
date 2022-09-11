// implementation of attention of vision saccade

import VSaccadeCommonDat;
import VSaccadeUtilities;

class VSaccade2 {
}

class ZZZ {
    public static function x(winnerSaccade: PathWithHdEncoding, arr: Array<DecoratedPathWithHdEncoding>, ctx: AttCtx) {
        var arr2 = arr.map(iv -> {val:iv, sim: VSaccadeUtilities.cmpSaccades(winnerSaccade, iv.payload, 0, 0)});
        function cmp(v:Float): Int {
            if(v == 0.0) { return 0; }
            else if(v > 0.0) { return 1; }
            return -1;
        }
        arr2.sort((a,b)->cmp(b.sim-a.sim));
        
        var idx=0;
        for (iv in arr2) {
            var isWinner: Bool = idx<ctx.topN;
            calcUpdateRule(isWinner, iv.sim, ctx.lr, iv.val.av);
            idx++;
        }
    }

    public static function calcUpdateRule(isWinner: Bool, sim: Float, lr: Float,  av: SaccadeAv) {
        av.v0 = (1.0-lr)*av.v0 + lr*(sim*(isWinner?1.0:0.0));
    }
}

class AttCtx {
    public var topN: Int = 3;
    public var lr: Float = 0.0001;

    public function new() {
    }
}

class SaccadeAv {
    public var v0: Float = 0.5;

    public function new() {}
}
