package g;

// ripped from 19NAR2
@:generic 
class ArrUtils<T> {
    public function new() {}

    public function removeAt(arr:Array<T>, idx:Int):Array<T> {
        var before = arr.slice(0, idx);
        var after = arr.slice(idx+1, arr.length);
        return before.concat(after);
    }

    /*
    public static function main() {
        trace(removeAt([0], 0));
        trace("---");
        trace(removeAt([0, 1], 0));
        trace(removeAt([0, 1], 1));
        trace("---");
        trace(removeAt([0, 1, 2], 0));
        trace(removeAt([0, 1, 2], 1));
        trace(removeAt([0, 1, 2], 2));
    }
    */
}
