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
}


