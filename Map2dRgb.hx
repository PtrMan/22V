class Map2dRgb {
    public var w: Int;
    public var h: Int;
    public var arr: Array<Rgb>;
    public function new(w:Int, h:Int) {
        this.w = w;
        this.h = h;
        arr = [];
        for(i in 0...w*h) {
            arr.push(new Rgb(0.0, 0.0, 0.0));
        }
    }

    public function writeAtSafe(y:Int, x:Int,  val:Rgb) {
        if(x < 0 || x >= w) {
            return;
        }
        if(y < 0 || y >= h) {
            return;
        }
        writeAtUnsafe(y,x,val);
    }
    public function writeAtUnsafe(y:Int, x:Int,  val:Rgb) {
        arr[x + y*w] = val;
    }

    public function readAtSafe(y:Int, x:Int): Rgb {
        if(x < 0 || x >= w) {
            return new Rgb(0.0, 0.0, 0.0);
        }
        if(y < 0 || y >= h) {
            return new Rgb(0.0, 0.0, 0.0);
        }
        return readAtUnsafe(y,x);
    }

    public inline function readAtUnsafe(y:Int, x:Int): Rgb {
        return arr[x + y*w];
    }
}

class Rgb {
    public var r: Float;
    public var g: Float;
    public var b: Float;
    public inline function new(r: Float, g: Float, b: Float) {
        this.r = r;
        this.g = g;
        this.b = b;
    }

    public static inline function sub(a: Rgb, b: Rgb): Rgb {
        return new Rgb(a.r-b.r, a.g-b.g, a.b-b.b);
    }
}
