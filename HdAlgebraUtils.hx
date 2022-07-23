import BRealvectorUtils;

//& utilities to compute with a algebra of hyperdimensional vectors
class HdAlgebraUtils {
    //& bind variable to value
    public static function varBind(var_: Array<Float>, val: Array<Float>): Array<Float> {
        return BRealvectorUtils.mul(val, var_);
    }

    //& unbind variable
    public static function varUnbind(var_: Array<Float>, param: Array<Float>): Array<Float> {
        return BRealvectorUtils.mul(param, var_);
    }

    //& creates a new variable and returns the value
    public static function createVar(vecLen:Int, rng:Rng0): Array<Float> {
        return BBitvectorUtils.convToReal(BBitvectorUtils.convToBoolVec(BRealvectorUtils.genRandom(vecLen, rng))); // convert twice to get a vector which has -1 and 1, which we can use as var
    }
}
