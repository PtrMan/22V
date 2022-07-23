class Map2dBool {
    public var w: Int;
    public var h: Int;
    public var arr: Array<Bool>;
    public function new(w:Int, h:Int) {
        this.w = w;
        this.h = h;
        arr = [];
        for(i in 0...w*h) {
            arr.push(false);
        }
    }

    public function writeAtSafe(y:Int, x:Int,  val:Bool) {
        if(x < 0 || x >= w) {
            return;
        }
        if(y < 0 || y >= h) {
            return;
        }
        arr[x + y*w] = val;
    }
    public function writeAtUnsafe(y:Int, x:Int,  val:Bool) {
        arr[x + y*w] = val;
    }

    public function readAtSafe(y:Int, x:Int): Bool {
        if(x < 0 || x >= w) {
            return false;
        }
        if(y < 0 || y >= h) {
            return false;
        }
        return arr[x + y*w];
    }
    public function readAtUnsafe(y:Int, x:Int): Bool {
        return arr[x + y*w];
    }
}
