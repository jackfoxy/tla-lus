import tlc2.output.MP;
import tlc2.TLCGlobals;

// Differential oracle for tlc2.output.MP.getMessage (R1.3.5.7).
// Each argv token is a vector "class:code:p1|p2|..." (params pipe-joined,
// empty for none). Dumps getMessage in BOTH -tool and plain mode, so the
// Hoon +mp-message renderer can byte-match. Terminates each with "%%".
public class MPDump {
    public static void main(String[] args) {
        for (String a : args) {
            String[] f = a.split(":", 3);
            int cls = Integer.parseInt(f[0].trim());
            int code = Integer.parseInt(f[1].trim());
            String[] p = (f.length < 3 || f[2].isEmpty())
                ? new String[0]
                : f[2].split("\\|", -1);
            TLCGlobals.tool = true;
            String tool = MP.getMessage(cls, code, p, true);
            TLCGlobals.tool = false;
            String plain = MP.getMessage(cls, code, p, false);
            System.out.println("### " + a);
            System.out.println("--TOOL--");
            System.out.println(tool);
            System.out.println("--PLAIN--");
            System.out.println(plain);
            System.out.println("%%");
        }
    }
}
