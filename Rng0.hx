import MathUtils2;

//& pseudorandom number generator
interface Rng0 {
    public function genInt(maxVal:Int): Int;
    public function genFloat01(): Float;
}

class FastRng0 implements Rng0 {
    public var state: Float; // = 3937583.0;
    
    public function new(seed) {
        state = seed;
    }
    public function genInt(maxVal:Int): Int {
        state += 129489.48027405927;

        var valF:Float = (1.0+Math.sin(state)) * maxVal * 2.0;
        var valI:Int = Std.int(valF) % maxVal;
        return valI;
    }

    public function genFloat01(): Float {
        return MathUtils2.convToFloat(genInt(100000)) / 100000.0;
    }
}

class CryptoRng0 implements Rng0 {
    public var state: String;
    
    public function new(seed) {
        this.state = seed;
    }

    public function genInt(maxVal:Int): Int {
        state = haxe.crypto.Sha1.encode(state);
        var v1: String = state.substr(16*2+1);

        var vi: Int = Std.parseInt("0x"+v1);
        return vi % maxVal;
    }

    public function genFloat01(): Float {
        return MathUtils2.convToFloat(genInt(100000)) / 100000.0;
    }
}