import Map2dRgb;

class Map2dRgbDraw {
    //& draw a box
    public static function drawBox(img:Map2dRgb, ax:Int,ay:Int,bx:Int,by:Int,color:Rgb) {
        for(iy in ay...by) {
            for(ix in ax...bx) {
                img.writeAtSafe(iy,ix,color);
            }
        }
    }

    //& draw a rect with is empty inside
    public static function drawRect(img:Map2dRgb, ax:Int,ay:Int,bx:Int,by:Int,color:Rgb) {
        drawBox(img, ax, ay, ax+1, by, color); //& left
        drawBox(img, bx-1, ay, bx, by, color); //& right

        drawBox(img, ax, ay, bx, ay+1, color); //& top
        drawBox(img, ax, by-1, bx, by, color);//& bottom
    }
}
