import haxe.Exception;
import Map2dRgb.Rgb;

import ColorFilter.ColorFilter1;
import ColorFilter.ColorFilter2;

// image operators which operate on images and do something
class ImageOperators {
    // compute average of image in a rect
    public static function calcAvgOverRect(img: Map2dRgb, ax:Int,ay:Int,bx:Int,by:Int): Rgb {
        trace('TODO - implement ImageOperators.calcAvgOverRect()');
        return new Rgb(0.0, 0.0, 0.0);
    }

    // threshold to boolean
    public static function calcBinaryByThreshold(img: Map2dFloat, threshold: Float): Map2dBool {
        var res = new Map2dBool(img.w,img.h);
        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                var v = img.readAtSafe(iy,ix); // TODO< readAtUnsafe() >
                res.writeAtSafe(iy,ix,v > threshold); // TODO< writeAtUnsafe() >
            }
        }
        return res;
    }

    // count how many pixels are true
    public static function countTrue(img: Map2dBool): Int {
        var res = 0;
        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                if (img.readAtSafe(iy,ix)) {
                    res++;
                }
            }
        }
        return res;
    }

    public static function applyFilter1(img: Map2dRgb, filter: ColorFilter1): Map2dRgb {
        var res = new Map2dRgb(img.w,img.h);
        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                var v = img.readAtUnsafe(iy,ix);
                v = filter.process(v);
                res.writeAtSafe(iy,ix,v); // TODO< writeAtUnsafe() >
            }
        }
        return res;
    }

    public static function applyFilter2(a: Map2dRgb, b: Map2dRgb, filter: ColorFilter2): Map2dRgb {
        // sanity check
        if (a.w != b.w || a.h != b.h) {
            throw new Exception("images have different sizes!!!");
        }

        var res = new Map2dRgb(a.w,a.h);
        for(iy in 0...a.h) {
            for(ix in 0...a.w) {
                var va = a.readAtUnsafe(iy,ix);
                var vb = b.readAtUnsafe(iy,ix);
                var v = filter.process(va,vb);
                res.writeAtSafe(iy,ix,v); // TODO< writeAtUnsafe() >
            }
        }
        return res;
    }

    public static function extractChannelRed(img: Map2dRgb): Map2dFloat {
        var res = new Map2dFloat(img.w,img.h);
        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                var v = img.readAtUnsafe(iy,ix);
                res.writeAtSafe(iy,ix,v.r); // TODO< writeAtUnsafe() >
            }
        }
        return res;
    }

    public static function convOneChannelToRgb(img: Map2dFloat): Map2dRgb {
        var res = new Map2dRgb(img.w,img.h);
        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                var v: Float = img.readAtUnsafe(iy,ix);
                res.writeAtSafe(iy,ix,new Map2dRgb.Rgb(v,v,v)); // TODO< writeAtUnsafe() >
            }
        }
        return res;
    }

    // keywords: metric
    // keywords: mean square error
    // keywords: MSE
    public static function calcMse(img: Map2dFloat): Float {
        var res: Float = 0.0;
        for(iy in 0...img.h) {
            for(ix in 0...img.w) {
                var v = img.readAtUnsafe(iy,ix);
                res += (v*v);
            }
        }
        return res;
    }

    // keywords: sub image
    public static function subImg(img: Map2dRgb, ax: Int, ay: Int, w: Int, h: Int): Map2dRgb {
        var res = new Map2dRgb(w,h);
        for(iy in 0...h) {
            for(ix in 0...w) {
                var v = img.readAtSafe(ay+iy,ax+ix);
                res.writeAtSafe(iy,ix,v);
            }
        }
        return res;
    }

    // keywords: sub image
    public static function subImgWithScalingByCenter(img: Map2dRgb, center:{x:Int,y:Int}, windowWidth:Float, outSize:Int): Map2dRgb {
        var res = new Map2dRgb(outSize,outSize);
        for(iy in 0...outSize) {
            for(ix in 0...outSize) {
                // interpolate
                var relX: Float = ix / (outSize-1); // [0.0;1.0]
                var relY: Float = iy / (outSize-1); // [0.0;1.0]
                var absX: Int = Std.int(relX*outSize);
                var absY: Int = Std.int(relY*outSize);
                var x: Int = center.x - Std.int(outSize/2) + absX;
                var y: Int = center.y - Std.int(outSize/2) + absY;

                var v = img.readAtSafe(y,x);
                res.writeAtSafe(iy,ix,v);
            }
        }
        return res;
    }

    // keywords: scale
    public static function scale(img: Map2dRgb, toWidth: Int): Map2dRgb {
        var factor: Float = toWidth / img.w;

        var res = new Map2dRgb(Std.int(img.w*factor),Std.int(img.h*factor));

        //trace('${res.w} ${res.h}');

        for(iy in 0...res.h) {
            for(ix in 0...res.w) {
                var srcX: Int = Std.int(ix/factor);
                var srcY: Int = Std.int(iy/factor);

                //trace('$srcX $srcY');

                var v = img.readAtSafe(srcY, srcX);
                res.writeAtSafe(iy,ix,v);
            }
        }
        return res;
    }

    // keywords: convolution
    public static function conv1(map: Map2dFloat, kernel: Map2dFloat): Map2dFloat {
        var halfWidthMinusOne: Int = Std.int((kernel.w-1)/2);

        var dest: Map2dFloat = new Map2dFloat(map.w, map.h);

        for(icy in 0...map.h) {
            for(icx in 0...map.w) {

                var acc: Float = 0.0;

                for(iDeltaY in -halfWidthMinusOne...halfWidthMinusOne+1) {
                    for(iDeltaX in -halfWidthMinusOne...halfWidthMinusOne+1) {
                        var kernelX: Int = iDeltaX+halfWidthMinusOne;
                        var kernelY: Int = iDeltaY+halfWidthMinusOne;
                        
                        var valKernel: Float = kernel.readAtUnsafe(kernelY, kernelX);
                        var valMap: Float = map.readAtSafe(icy+iDeltaY,icx+iDeltaX);

                        acc += (valKernel*valMap);
                    }
                }

                dest.writeAtSafe(icy,icx,acc);
            }
        }

        return dest;
    }
}
