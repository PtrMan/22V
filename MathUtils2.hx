class MathUtils2 {
    public static function convToFloat(v:Int): Float {
        return v;
    }

    public static function maxInt(a:Int, b: Int): Int {
        return a>b?a:b;
    }

    public static function minInt(a:Int, b: Int): Int {
        return a<b?a:b;
    }

    public static function absInt(v:Int): Int {
        return v>0?v:-v;
    }

    public static function convTo01Range(val:Float, minVal:Float, maxVal:Float) {
        return (val-minVal)/(maxVal-minVal);
    }

    // helper which return -1 if value is below 0.0, 0 if its equal and 1 if it is above 0.0
    public static function sign(v:Float): Int {
        if (v > 0.0) {
            return 1;
        }
        else if (v < 0.0) {
            return -1;
        }
        return 0;
    }

    public static function clampInt(v:Int, a:Int, b:Int): Int {
        return maxInt(minInt(b, v), a);
    }
}


