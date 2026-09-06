import tla2sany.drivers.SANY;
import tla2sany.drivers.SanySettings;
import tla2sany.modanalyzer.SpecObj;
import tla2sany.output.LogLevel;
import tla2sany.output.SimpleSanyOutput;
import tlc2.tool.impl.FastTool;
import util.SimpleFilenameToStream;
import util.ToolIO;
import util.UniqueString;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * UniqueString interning-order oracle for unit 6C, subunit C1.7 (family 5).
 *
 * TLC orders StringValues and ModelValues by their UniqueString `tok` — the
 * position at which the string was first interned during the run — and folds
 * a model value's tok into its fingerprint. Reproducing that order requires
 * knowing exactly what is interned, in what order, and by which phase. This
 * dumps the whole InternTable at three points:
 *
 *   BASELINE   before any spec is read (JVM/TLC startup only)
 *   SANY       after tla2sany parses and analyzes the module
 *   TOOL       after tlc2 builds a FastTool (SANY + SpecProcessor + config)
 *
 * Usage: InternDump <base>   (cwd holds <base>.tla and <base>.cfg)
 *
 * Each section prints `<tok> <string>` in tok order, so a diff between two
 * sections is exactly what that phase interned. The counts on the section
 * header lines are the numbers the C1.7 decision rests on.
 */
public final class InternDump {

  public static void main(String[] args) throws Exception {
    if (args.length > 1 && args[0].equals("--values")) {
      values(args[1]);
      return;
    }
    String base = args[0];
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));

    StringBuilder out = new StringBuilder();
    List<String> baseline = snapshot();
    section(out, "BASELINE", baseline, null);

    ByteArrayOutputStream errBuf = new ByteArrayOutputStream();
    PrintStream errPs = new PrintStream(errBuf, true, "UTF-8");
    SpecObj spec = new SpecObj(base, new SimpleFilenameToStream());
    try {
      SANY.parse(spec, base, new SimpleSanyOutput(errPs, LogLevel.ERROR),
                 new SanySettings(true, true, true, false));
    } catch (Throwable t) {
      out.append("SANY-FAILED ").append(t.getClass().getSimpleName()).append("\n");
    }
    List<String> afterSany = snapshot();
    section(out, "SANY", afterSany, baseline);

    try {
      new FastTool(base, base, new SimpleFilenameToStream());
    } catch (Throwable t) {
      out.append("TOOL-FAILED ").append(t.getClass().getSimpleName()).append("\n");
    }
    List<String> afterTool = snapshot();
    section(out, "TOOL", afterTool, afterSany);
    System.out.print(out);
    // the same values, but reached after SANY has already interned the
    // module's strings: if the renderings differ from the --values run, the
    // observable order depends on the driver's phase order, not on the spec
    values(base);
  }

  /** Which interned string backs each value: for every arity-0 root
   *  definition, the value's rendering and, for the strings and model values
   *  inside it, their UniqueString tok in element order. This is what decides
   *  whether TLC's rendering order is the interning order. */
  private static void values(String base) {
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    StringBuilder out = new StringBuilder("VALUES\n");
    FastTool tool;
    try {
      tool = new FastTool(base, base, new SimpleFilenameToStream());
    } catch (Throwable t) {
      out.append("LOAD ! ").append(t.getClass().getSimpleName()).append("\n");
      System.out.print(out);
      return;
    }
    tla2sany.semantic.ModuleNode root = tool.getModule(base);
    tla2sany.semantic.OpDefNode[] defs = root.getOpDefs();
    java.util.Arrays.sort(defs, java.util.Comparator.comparing(d -> d.getName().toString()));
    for (tla2sany.semantic.OpDefNode d : defs) {
      if (d.getArity() != 0) continue;
      if (d.getOriginallyDefinedInModuleNode() == null) continue;
      if (!d.getOriginallyDefinedInModuleNode().getName().toString().equals(base)) continue;
      try {
        tlc2.value.impl.Value v = (tlc2.value.impl.Value) tool.eval(d.getBody());
        out.append(d.getName()).append(" ").append(v.toString())
           .append("  toks:").append(toks(v)).append("\n");
      } catch (Throwable t) {
        out.append(d.getName()).append(" ! ").append(t.getClass().getSimpleName()).append("\n");
      }
    }
    System.out.print(out);
  }

  /** the toks of the strings/model values inside a value, in element order */
  private static String toks(tlc2.value.impl.Value v) {
    StringBuilder sb = new StringBuilder();
    if (v instanceof tlc2.value.impl.StringValue) {
      sb.append(" ").append(((tlc2.value.impl.StringValue) v).getVal().toString())
        .append("=").append(((tlc2.value.impl.StringValue) v).getVal().getTok());
    } else if (v instanceof tlc2.value.impl.ModelValue) {
      sb.append(" ").append(v.toString()).append("=")
        .append(((tlc2.value.impl.ModelValue) v).val.getTok());
    } else if (v instanceof tlc2.value.impl.SetEnumValue) {
      for (int i = 0; i < ((tlc2.value.impl.SetEnumValue) v).elems.size(); i++) {
        sb.append(toks(((tlc2.value.impl.SetEnumValue) v).elems.elementAt(i)));
      }
    } else if (v instanceof tlc2.value.impl.TupleValue) {
      for (tlc2.value.impl.Value e : ((tlc2.value.impl.TupleValue) v).elems) sb.append(toks(e));
    } else if (v instanceof tlc2.value.impl.RecordValue) {
      for (util.UniqueString k : ((tlc2.value.impl.RecordValue) v).names) {
        sb.append(" ").append(k.toString()).append("=").append(k.getTok());
      }
    }
    return sb.toString();
  }

  /** every interned string in tok order, as "<tok> <string>" */
  private static List<String> snapshot() {
    List<String> rows = new ArrayList<>();
    if (UniqueString.internTbl == null) return rows;
    Map<String, UniqueString> m = UniqueString.internTbl.toMap();
    int max = 0;
    for (UniqueString us : m.values()) max = Math.max(max, us.getTok());
    for (int tok = 0; tok <= max; tok++) {
      UniqueString us = UniqueString.uidToUniqueString(tok);
      if (us == null) continue;
      rows.add(tok + " " + us.toString());
    }
    return rows;
  }

  /** print a section: its size, and the rows this phase added */
  private static void section(StringBuilder out, String name, List<String> now,
                              List<String> before) {
    int added = (before == null) ? now.size() : now.size() - before.size();
    out.append("== ").append(name).append(" total=").append(now.size())
       .append(" added=").append(added).append("\n");
    int from = (before == null) ? 0 : before.size();
    for (int i = from; i < now.size(); i++) {
      out.append(now.get(i)).append("\n");
    }
  }
}
