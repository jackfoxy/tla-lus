import tlc2.tool.EvalException;
import tlc2.tool.impl.FastTool;
import tlc2.value.impl.Value;
import tla2sany.semantic.ModuleNode;
import tla2sany.semantic.OpDefNode;
import util.SimpleFilenameToStream;
import util.ToolIO;

import java.util.Arrays;
import java.util.Comparator;

/**
 * Evaluates the arity-0 definitions of a module through tlc2.tool.impl.Tool
 * for the unit-6 (core TLC value/evaluation) differential oracle.
 *
 * Usage: EvalDump <base>   (cwd holds <base>.tla and <base>.cfg)
 *
 * Builds a FastTool (SANY parse/analyze + SpecProcessor config, so CONSTANT
 * assignments and model values from the config are in scope), then for every
 * arity-0 operator defined in the root module (source order by name) evaluates
 * its body with tool.eval and prints a stable projection:
 *
 *   EVAL
 *   <name> <kind> <canonical-value>          (kind = value class, UID-free)
 * or
 *   <name> ! EC<code> <ExceptionClass>: <message>   (a typed evaluation failure)
 *
 * Java object identities, coverage counters, and timing are excluded; values
 * render via Value.toString (TLC's canonical rendering, as the REPL uses).
 */
public final class EvalDump {

  public static void main(String[] args) {
    String base = args[0];
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    StringBuilder out = new StringBuilder("EVAL\n");
    FastTool tool;
    try {
      tool = new FastTool(base, base, new SimpleFilenameToStream());
    } catch (Throwable t) {
      out.append("LOAD ! ").append(t.getClass().getSimpleName())
         .append(": ").append(msg(t)).append("\n");
      System.out.print(out);
      return;
    }
    ModuleNode root = tool.getModule(base);
    OpDefNode[] defs = root.getOpDefs();
    OpDefNode[] sorted = Arrays.copyOf(defs, defs.length);
    Arrays.sort(sorted, Comparator.comparing(d -> d.getName().toString()));
    for (OpDefNode d : sorted) {
      if (d.getArity() != 0) continue;
      // only definitions originating in the root module
      if (d.getOriginallyDefinedInModuleNode() == null) continue;
      if (!d.getOriginallyDefinedInModuleNode().getName().toString().equals(base)) continue;
      String name = d.getName().toString();
      try {
        Value v = (Value) tool.eval(d.getBody());
        out.append(name).append(" ").append(kind(v)).append(" ").append(v.toString()).append("\n");
      } catch (Throwable t) {
        out.append(name).append(" ! ").append(ec(t))
           .append(t.getClass().getSimpleName())
           .append(": ").append(msg(t)).append("\n");
      }
    }
    System.out.print(out);
  }

  /** `EC<code> ` for a typed TLC failure, empty otherwise (as ModuleOpDump). */
  private static String ec(Throwable t) {
    if (t instanceof EvalException) {
      return "EC" + ((EvalException) t).getErrorCode() + " ";
    }
    return "";
  }

  private static String kind(Value v) {
    // stable kind discriminator: the value class simple name (UID-free)
    return v.getClass().getSimpleName();
  }

  private static String msg(Throwable t) {
    String m = t.getMessage();
    if (m == null) return "";
    return m.replace("\n", " ").trim();
  }
}
