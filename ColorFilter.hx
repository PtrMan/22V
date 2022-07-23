import Map2dRgb;

class ColorFilter {} // dummy class

// interface to seperate kernel of color filtering from actual filtering
interface ColorFilter1 {
    function process(c: Rgb): Rgb;
}

// interface for color filter with two inputs
interface ColorFilter2 {
    function process(a: Rgb, b: Rgb): Rgb;
}

// compute distance of colors
class ColorFilter1Distance implements ColorFilter1 {
    public var detecting: Rgb;
    
    public function new(detecting) {
        this.detecting = detecting;
        
    }
    public function process(c: Rgb): Rgb {
        var rDiff: Float = Math.abs(c.r - detecting.r);
        var gDiff: Float = Math.abs(c.g - detecting.g);
        var bDiff: Float = Math.abs(c.b - detecting.b);
        return new Rgb(1.0-rDiff,1.0-gDiff,1.0-bDiff);
    }
}

// convert to grayscale with the simplest method
class ColorFilter1ConvToGrayscale implements ColorFilter1 {
    public function new() {}
    public function process(c: Rgb): Rgb {
        var v: Float = (c.r+c.g+c.b)/3.0;
        return new Rgb(v,v,v);
    }
}

// absolute value
class ColorFilter1Abs implements ColorFilter1 {
    public function new() {}
    public function process(c: Rgb): Rgb {
        return new Rgb(Math.abs(c.r),Math.abs(c.g),Math.abs(c.b));
    }
}

// compute difference of two images without special handling for negative values
class ColorFilter2CalcDiff implements ColorFilter2 {
    public function new() {}
    public function process(a: Rgb, b: Rgb): Rgb {
        var r = a.r - b.r;
        var g = a.g - b.g;
        var b = a.b - b.b;
        return new Rgb(r,g,b);
    }
}
