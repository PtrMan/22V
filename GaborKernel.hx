// keywords: Kernel
// keywords: Gabor
// keywords: Convolution
class GaborKernel {
    /**
     * 
     * \param phi angle in radiants
     * \param spartialRatioAspect ellipticity of the support of the Gabor function
     */
    public static function generateGaborKernel(width: Int, phi:Float, lambda:Float, phaseOffset:Float, spartialRatioAspect:Float): Map2dFloat {
        
        // constant from http://bmia.bmt.tue.nl/Education/Courses/FEV/course/pdf/Petkov_Gabor_functions2011.pdf
        var sigma: Float = 0.56 * lambda;

        var resultMap: Map2dFloat = new Map2dFloat(width, width);

        for (yInt in 0...width) {
            for (xInt in 0...width) {
                var x: Float = ((xInt - width / 2) / width) * 2.0;
                var y: Float = ((yInt - width / 2) / width) * 2.0;

                var xTick: Float = x * Math.cos(phi) + y * Math.sin(phi);
                var yTick: Float = -x * Math.sin(phi) + y * Math.cos(phi);

                var insideExp: Float = -(xTick*xTick + spartialRatioAspect*spartialRatioAspect * yTick*yTick)/(2.0*sigma*sigma);
                var insideCos: Float = 2.0*Math.PI * (xTick/lambda) + phaseOffset;

                var filterValue: Float = Math.exp(insideExp)*Math.cos(insideCos);
                
                //trace('$filterValue'); // DBG

                resultMap.writeAtSafe(yInt, xInt, filterValue);
            }
        }

        return resultMap;
    }
}
