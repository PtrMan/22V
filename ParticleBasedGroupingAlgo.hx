
// implementation of algorithm to group regions by motion


class ParticleBasedGroupingAlgo {
    public var setting__clusterQuadSize: Int = 10; // how many pixels is each clustering-quad wide?
    public var setting__quantizationRanges: Int = 3; // 3 // how many ranges are used for quantification in each positive / negative number direction

    public var setting__velScale: Float = 100.0; // scale of velocity before it's put into buckets for grouping

    public var activeParticles: Array<MotionParticle> = [];

    public var outCurrentFrameClusters: Array<MotionParticleCluster> = [];

    public function new() {}

    public function process(flowX: Map2dFloat, flowY: Map2dFloat) {
        outCurrentFrameClusters = [];



        // * carry particles with flow
        {
            for (iParticle in activeParticles) {
                var idxX: Int = Std.int(iParticle.pos.x);
                var idxY: Int = Std.int(iParticle.pos.y);
                var flowXVal: Float = flowX.readAtSafe(idxY,idxX);
                var flowYVal: Float = flowY.readAtSafe(idxY,idxX);

                // flow
                iParticle.pos.x += flowXVal;
                iParticle.pos.y += flowYVal;

                // read velocity
                var velX: Float = flowX.readAtSafe(Std.int(iParticle.pos.y), Std.int(iParticle.pos.x));
                var velY: Float = flowY.readAtSafe(Std.int(iParticle.pos.y), Std.int(iParticle.pos.x));
                iParticle.vel.x = velX;
                iParticle.vel.y = velY;
            }
        }

        // * remove old particles on the sides
        {
            function filterPredicate(particle: MotionParticle): Bool {
                return particle.pos.x >= 0.0 && particle.pos.x < flowX.w && particle.pos.y >= 0 && particle.pos.y < flowX.h;
            }

            activeParticles = activeParticles.filter(filterPredicate);
        }

        // * reseed particles
        {
            var thisBitmap: ClusterBitmap = new ClusterBitmap(Std.int(flowX.w/setting__clusterQuadSize), Std.int(flowX.h/setting__clusterQuadSize));

            // *** fill bitmap
            for (iParticle in activeParticles) {
                var idxX: Int = Std.int(iParticle.pos.x / setting__clusterQuadSize);
                var idxY: Int = Std.int(iParticle.pos.y / setting__clusterQuadSize);
                var idx: Null<Int> = thisBitmap.calcIdx(idxY,idxX);
                if (idx != null) {
                    thisBitmap.dat[idx].content.push(iParticle);
                }
            }

            for (j in 0...thisBitmap.h) {
                for (i in 0...thisBitmap.w) {
                    var idx: Int = thisBitmap.calcIdx(j,i);
                    if (thisBitmap.dat[idx].content.length == 0) {
                        // add particles in this square
                        for (z in 0...10) {
                            var posX: Float = i*setting__clusterQuadSize + Math.random()*setting__clusterQuadSize;
                            var posY: Float = j*setting__clusterQuadSize + Math.random()*setting__clusterQuadSize;

                            // read velocity from flow maps
                            var vel:Vec2 = new Vec2(0.0,0.0);
                            vel.x = flowX.readAtSafe(Std.int(posY), Std.int(posX));
                            vel.y = flowY.readAtSafe(Std.int(posY), Std.int(posX));

                            activeParticles.push(new MotionParticle(new Vec2(posX,posY), vel));
                        }
                    }
                }
            }
        }


        Sys.println('cnt = ${activeParticles.length}');


        // * group
        {


            // ** put each particle in the respectivly bucket by velocity
            function calcBucketIdxByVel(vel: Vec2): Int {
                var velXInt: Int = Std.int(vel.x * setting__velScale);
                velXInt = setting__quantizationRanges + MathUtils2.clampInt(velXInt, -setting__quantizationRanges, setting__quantizationRanges);

                var velYInt: Int = Std.int(vel.y * setting__velScale);
                velYInt = setting__quantizationRanges + MathUtils2.clampInt(velYInt, -setting__quantizationRanges, setting__quantizationRanges);

                var bucketIdx: Int = velXInt + velYInt*(setting__quantizationRanges*2+1);
                return bucketIdx;
            }

            var buckets: Array<MotionParticleBucket> = [];
            for (k in 0...(setting__quantizationRanges*2+1)*(setting__quantizationRanges*2+1)) {
                buckets.push(new MotionParticleBucket());
            }

            for (iParticle in activeParticles) {
                var bucketIdx: Int = calcBucketIdxByVel(iParticle.vel);
                buckets[bucketIdx].arr.push(iParticle);
            }



            // ** group in each bucket by distance
            for (iBucket in buckets) {
                // algorithm: we put it into a 2d bitmap, then we cluster the regions, then we pull out the particles
                
                

                

                var thisBitmap: ClusterBitmap = new ClusterBitmap(Std.int(flowX.w/setting__clusterQuadSize), Std.int(flowX.h/setting__clusterQuadSize));

                // *** fill bitmap
                for (iParticle in iBucket.arr) {
                    var idxX: Int = Std.int(iParticle.pos.x / setting__clusterQuadSize);
                    var idxY: Int = Std.int(iParticle.pos.y / setting__clusterQuadSize);
                    var idx: Null<Int> = thisBitmap.calcIdx(idxY,idxX);
                    if (idx != null) {
                        thisBitmap.dat[idx].content.push(iParticle);
                    }
                }

                // *** cluster
                var bitmapOfThisBitmap: Map2dBool = ClusterBitmap.convToBitmap(thisBitmap);
                var groupIdMap: Map2dInt = ImageGrouping.group(bitmapOfThisBitmap); // group and return bitmap of group id's

                // *** make sense of clusters
                // **** convert to map by group-ids
                var particlesByGroupId: Map<Int, Array<MotionParticle>> = new Map<Int, Array<MotionParticle>>();
                for (j in 0...groupIdMap.h) {
                    for (i in 0...groupIdMap.w) {
                        var groupId: Int = groupIdMap.readAtSafe(j,i);
                        if (groupId != 0) { // is this assigned a group?
                            if (!particlesByGroupId.exists(groupId)) {
                                particlesByGroupId[groupId] = [];
                            }

                            for (iParticle in thisBitmap.dat[ thisBitmap.calcIdx(j,i) ].content) {
                                particlesByGroupId[groupId].push(iParticle);
                            }
                        }
                    }
                }

                // **** iterate over map by group-ids and put the particles into the groups
                for (iKeyValue in particlesByGroupId.keyValueIterator()) {
                    var thisCluster: MotionParticleCluster = new MotionParticleCluster(iKeyValue.value);
                    outCurrentFrameClusters.push(thisCluster); // add the cluster to the result

                    Sys.println('found group');
                }
            }
        }
    }
}

class ClusterBitmap {
    public var w: Int;
    public var h: Int;
    public var dat: Array<ClusterBitmapItem>;
    
    public function new(w: Int, h: Int) {
        this.w = w;
        this.h = h;

        dat = [];
        for(k in 0...w*h) {
            dat.push(new ClusterBitmapItem());
        }
    }

    public function calcIdx(y: Int, x: Int): Null<Int> {
        if (y < 0 || x < 0 || x >= w || y >= h) {
            return null;
        }
        return x + y*w;
    }

    // computes a bitmap if cells are used or not
    public static function convToBitmap(in_: ClusterBitmap): Map2dBool {
        var res: Map2dBool = new Map2dBool(in_.w, in_.h);
        for(j in 0...in_.h) {
            for(i in 0...in_.w) {
                res.writeAtUnsafe(j,i,in_.dat[ in_.calcIdx(j,i) ].content.length > 0);
            }
        }
        return res;
    }
}

class ClusterBitmapItem {
    public var content: Array<MotionParticle> = [];
    public function new() {}
}


class MotionParticleBucket {
    public var arr: Array<MotionParticle> = [];
    public function new() {}
}

// tracked particle
class MotionParticle {
    public var pos: Vec2;
    public var vel: Vec2;

    public function new(pos, vel) {
        this.pos = pos;
        this.vel = vel;
    }
}

// cluster of motion particles
class MotionParticleCluster {
    public var arr: Array<MotionParticle> = [];
    public function new(arr) {
        this.arr = arr;
    }

    public function calcAabb(): {min:Vec2,max:Vec2} {
        var min: Vec2 = new Vec2(10e10, 10e10);
        var max: Vec2 = new Vec2(-10e10,-10e10);

        for(iParticle in arr) {
            min.x = Math.min(min.x, iParticle.pos.x);
            min.y = Math.min(min.y, iParticle.pos.y);
            max.x = Math.max(max.x, iParticle.pos.x);
            max.y = Math.max(max.y, iParticle.pos.y);
        }

        return {min:min,max:max};
    }
}
