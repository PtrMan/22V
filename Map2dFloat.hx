class Map2dFloat {
    public var w: Int;
    public var h: Int;
    public var arr: Array<Float>;
    public function new(w:Int, h:Int) {
        this.w = w;
        this.h = h;
        arr = [];
        for(i in 0...w*h) {
            arr.push(0.0);
        }
    }

    public function writeAtSafe(y:Int, x:Int,  val:Float) {
        if(x < 0 || x >= w) {
            return;
        }
        if(y < 0 || y >= h) {
            return;
        }
        writeAtUnsafe(y,x,val);
    }
    public function writeAtUnsafe(y:Int, x:Int,  val:Float) {
        arr[x + y*w] = val;
    }

    public function readAtSafe(y:Int, x:Int): Float {
        if(x < 0 || x >= w) {
            return 0.0;
        }
        if(y < 0 || y >= h) {
            return 0.0;
        }
        return readAtUnsafe(y, x);
    }

    public inline function readAtUnsafe(y:Int, x:Int): Float {
        return arr[x + y*w];
    }
}
