
// abstraction for GC'ing to make sets etc. AIKR compatible
@:generic
class AikrGc<PayloadType> {
    public var arr: Array<PayloadType> = [];

    // used to limit under AIKR
    public var nEntriesMax: Int = 0;

    public var sortFn: (a: PayloadType, b: PayloadType)->Int;

    // /param sortFn function used to sort the entities when doing gc
    public function new(nEntriesMax: Int, sortFn: (a: PayloadType, b: PayloadType)->Int) {
        this.nEntriesMax = nEntriesMax;
        this.sortFn = sortFn;
    }

    public function push(v: PayloadType) {
        arr.push(v);
    }

    public function gc() {
        if (arr.length < nEntriesMax) {
            return; // no need for GC
        }

        var inplace: Array<PayloadType> = arr.copy();
    
        // * sort by criterion
        inplace.sort(sortFn);
        
        var inplaceKeep: Array<PayloadType> = inplace.slice(0, nEntriesMax);
        arr = inplaceKeep;
    }
}
