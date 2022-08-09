class CfgParser {
    public static function parse(fileContent: String): Map<String, Invariant> {
        var res: Map<String, Invariant> = new Map<String, Invariant>();
        
        for (iLine in fileContent.split("\n")) {
            var idxComment: Int = iLine.indexOf("#");
            if (idxComment != -1) {
                iLine = iLine.substr(0, idxComment); // cut away everything after comment
            }

            if (iLine.length == 0) {
                continue; // ignore empty lines
            }

            var sep: Array<String> = iLine.split("=");
            if (sep.length != 2) {
                // invalid config line, ignore
                continue;
            }

            var key: String = sep[0];
            var valStr: String = sep[1];

            var val: Invariant = Real(0.0);

            if (valStr.charAt(0) == '"') { // is it a string?
                var strVal: String = valStr.substr(1, valStr.length-2);
                val = Invariant.String(strVal);
            }
            else if (valStr.indexOf(".") != -1) {
                val = Invariant.Real(Std.parseFloat(valStr));
            }
            else {
                val = Invariant.Int(Std.parseInt(valStr));
            }

            res.set(key, val);
        }

        return res;
    }
}

enum Invariant {
    Real(v: Float);
    Int(v: Int);
    String(v: String);
}

class InvariantUtils {
    public static function retReal(v: Invariant): Float {
        switch (v) {
            case Real(v2): return v2;
            case _: return 0.0;
        }
    }
}
