import tlc2.tool.impl.FastTool;
import tla2sany.st.Location;
import util.Assert;
import util.SimpleFilenameToStream;
import util.ToolIO;

/**
 * Drives tlc2.tool.impl.Tool (SANY parse -> SpecProcessor.processConfig) on a
 * paired <base>.tla + <base>.cfg for the unit-5.3 config-vs-graph validation
 * oracle, and reports the SpecProcessor verdict.
 *
 * Usage: ConfigValidate <base>   (cwd holds <base>.tla and <base>.cfg)
 *
 * SpecProcessor.processConfig fails fast: the first TLC_CONFIG_* violation
 * throws Assert.TLCRuntimeException (errorCode + rendered message; the
 * detailed subclass also carries a SemanticNode span). So there is at most
 * one config-semantic diagnostic per file. Prints:
 *   VALIDATE
 *   ok                         (config accepted)
 * or
 *   VALIDATE
 *   <code> <span>              (span = bl.bc-el.ec, or ~ if none)
 *   <rendered message>
 */
public final class ConfigValidate {

  public static void main(String[] args) {
    String base = args[0];
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    StringBuilder out = new StringBuilder("VALIDATE\n");
    try {
      new FastTool(base, base, new SimpleFilenameToStream());
      out.append("ok\n");
    } catch (Assert.TLCDetailedRuntimeException e) {
      out.append(e.errorCode).append(" ").append(span(e.expr == null ? null : e.expr.getLocation()))
         .append("\n").append(nl(e.getMessage()));
    } catch (Assert.TLCRuntimeException e) {
      out.append(e.errorCode).append(" ~\n").append(nl(e.getMessage()));
    } catch (Throwable t) {
      out.append("THROW ").append(t.getClass().getSimpleName()).append("\n")
         .append(nl(String.valueOf(t.getMessage())));
    }
    System.out.print(out);
  }

  private static String span(Location l) {
    if (l == null || l == Location.nullLoc) return "~";
    return l.beginLine() + "." + l.beginColumn() + "-" + l.endLine() + "." + l.endColumn();
  }

  private static String nl(String s) {
    return s.endsWith("\n") ? s : s + "\n";
  }
}
