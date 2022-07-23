// latex eport emitter
class PROTOExportLatex {
    public static function emitDocumentIntro(ctx: ExportLatexCtx) {
        //ctx.buffer = ctx.buffer + "\\documentclass[tikz]{standalone}\n";
        //ctx.buffer = ctx.buffer + "\\begin{document}\n";
        //ctx.buffer = ctx.buffer + "\\begin{tikzpicture}\n";



        ctx.buffer = ctx.buffer + "\\documentclass{article}\n";
        ctx.buffer = ctx.buffer + "\\usepackage{tikz}\n";
        ctx.buffer = ctx.buffer + "\\begin{document}\n";
    }

    public static function emitDocumentOuttro(ctx: ExportLatexCtx) {
        //ctx.buffer = ctx.buffer + "\\end{tikzpicture}\n";
        ctx.buffer = ctx.buffer + "\\end{document}\n";
    }






    public static function emitTikzPreamble(ctx: ExportLatexCtx) {
        ctx.buffer = ctx.buffer + "\\begin{figure}[h!]";
        ctx.buffer = ctx.buffer + "\\begin{center}";
        ctx.buffer = ctx.buffer + "\\begin{tikzpicture}";

        
        // force bounding box, see  https://tex.stackexchange.com/questions/75449/specifying-the-width-and-height-of-a-tikzpicture -> https://tex.stackexchange.com/a/75456
        ctx.buffer = ctx.buffer + "\\draw[use as bounding box] (0,0) rectangle (14,8);\n";
    }

    public static function emitTikzPostamble(ctx: ExportLatexCtx) {
        ctx.buffer = ctx.buffer + "\\end{tikzpicture}\n";
        ctx.buffer = ctx.buffer + "\\end{center}\n";
        ctx.buffer = ctx.buffer + "\\end{figure}\n";
    }







    public static function emitTikzTextnode(text: String, pos: {x:Float,y:Float}, ctx: ExportLatexCtx) {
        ctx.buffer = ctx.buffer + '   \\node at (${pos.x},${pos.y}) {$text};\n';
    }

    // emit tikz instruction to draw a path of lines
    public static function emitTikzLinePath(path: Array<{x:Float,y:Float}>,  ctx: ExportLatexCtx) {
        var s: String = path.map(iv->'(${iv.x},${iv.y})').join(" -- ");      
        ctx.buffer = ctx.buffer + '   \\draw $s;\n';
    }

    // emit tikz instruction to draw a box
    public static function emitTikzBox(a: {x:Float,y:Float}, b: {x:Float,y:Float},  ctx:ExportLatexCtx) {
        var s: String = '   \\draw (${a.x},${a.y}) -- (${b.x},${a.y}) -- (${b.x},${b.y}) -- (${a.x},${b.y}) -- (${a.x},${a.y});\n';
        ctx.buffer = ctx.buffer + s;
    }
}

// context for latex output
class ExportLatexCtx {
    public var buffer: String = "";
    public function new() {}
}

// helper to write to file



//  \node[anchor=south west,inner sep=0] at (0,0) {\includegraphics[width=\textwidth]{ice_flow.gif}};
//  \draw[red,ultra thick,rounded corners] (7.5,5.3) rectangle (9.4,6.2);

