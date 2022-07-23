class Vec2 {
    public var x: Float;
    public var y: Float;

    public function new(x,y) {
        this.x = x;
        this.y = y;
    }

    public static function add(a: Vec2, b: Vec2): Vec2 {
        return new Vec2(a.x+b.x,a.y+b.y);
    }
    public static function scale(v: Vec2, s: Float): Vec2 {
        return new Vec2(v.x*s,v.y*s);
    }
}
