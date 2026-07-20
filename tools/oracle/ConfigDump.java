import tlc2.tool.impl.ModelConfig;
import tlc2.tool.ConfigFileException;
import tlc2.util.Vect;
import tlc2.value.IValue;
import util.SimpleFilenameToStream;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Hashtable;
import java.util.List;

/**
 * Dumps a normalized, UID-free projection of a TLC .cfg file parsed by
 * {@link tlc2.tool.impl.ModelConfig} for differential unit-5 testing.
 *
 * Usage: ConfigDump <file.cfg>   (run with cwd = the case dir)
 *
 * On a successful parse it prints a CONFIG section: one line per stored
 * section value in a fixed, deterministic order (single-value keys, then
 * ordered list keys, then constant assignments/overrides/module maps with
 * their keys sorted), values rendered canonically via IValue.toString(),
 * followed by a RAW section echoing getRawConstants() verbatim (each entry
 * delimited by a --- line) since downstream tooling reads it byte-for-byte.
 *
 * On the first ConfigFileException (ModelConfig.parse throws on the first
 * malformed construct) it prints a CONFIG-ERROR section with the exact
 * rendered message. Volatile Value heap identities are never printed.
 */
public final class ConfigDump {

  public static void main(String[] args) throws Exception {
    String path = args[0];
    ModelConfig cfg = new ModelConfig(path, new SimpleFilenameToStream());
    StringBuilder out = new StringBuilder();
    try {
      cfg.parse();
    } catch (ConfigFileException e) {
      out.append("CONFIG-ERROR\n");
      out.append(e.getMessage());
      if (!e.getMessage().endsWith("\n")) out.append("\n");
      System.out.print(out);
      return;
    }
    out.append("CONFIG\n");
    emitScalar(out, "init", cfg.getInit());
    emitScalar(out, "next", cfg.getNext());
    emitScalar(out, "spec", cfg.getSpec());
    emitScalar(out, "view", cfg.getView());
    emitScalar(out, "symmetry", cfg.getSymmetry());
    emitScalar(out, "alias", cfg.getAlias());
    emitScalar(out, "periodic", cfg.getPeriodic());
    emitScalar(out, "rlreward", cfg.getRLReward());
    out.append("deadlock ").append(cfg.getCheckDeadlock()).append("\n");
    emitList(out, "invariant", cfg.getInvariants());
    emitList(out, "property", cfg.getProperties());
    emitList(out, "constraint", cfg.getConstraints());
    emitList(out, "action-constraint", cfg.getActionConstraints());
    emitList(out, "postcondition", cfg.getPostConditions());
    emitList(out, "possible", cfg.getPossible());
    // constant assignments (order preserved as parsed)
    Vect constants = cfg.getConstants();
    for (int i = 0; i < constants.size(); i++) {
      out.append("const ").append(renderLine((Vect) constants.elementAt(i))).append("\n");
    }
    // main-module overrides, sorted by lhs
    Hashtable<String, String> ov = cfg.getOverrides();
    List<String> ks = new ArrayList<>(ov.keySet());
    Collections.sort(ks);
    for (String k : ks) {
      out.append("override ").append(k).append(" <- ").append(ov.get(k)).append("\n");
    }
    // module overrides, sorted by module then lhs
    Hashtable modOv = cfg.getModOverrides();
    List<String> mos = new ArrayList<>(modOv.keySet());
    Collections.sort(mos);
    for (String m : mos) {
      Hashtable<String, String> defs = (Hashtable<String, String>) modOv.get(m);
      List<String> dk = new ArrayList<>(defs.keySet());
      Collections.sort(dk);
      for (String k : dk) {
        out.append("mod-override ").append(m).append(" ")
           .append(k).append(" <- ").append(defs.get(k)).append("\n");
      }
    }
    // module constants, sorted by module (lines in parse order within a module)
    Hashtable modC = cfg.getModConstants();
    List<String> mcs = new ArrayList<>(modC.keySet());
    Collections.sort(mcs);
    for (String m : mcs) {
      Vect lines = (Vect) modC.get(m);
      for (int i = 0; i < lines.size(); i++) {
        out.append("mod-const ").append(m).append(" ")
           .append(renderLine((Vect) lines.elementAt(i))).append("\n");
      }
    }
    // raw constant buffers, verbatim
    List<String> raw = cfg.getRawConstants();
    out.append("RAW\n");
    for (String r : raw) {
      out.append(r).append("\n---\n");
    }
    System.out.print(out);
  }

  private static void emitScalar(StringBuilder out, String key, String v) {
    if (v != null && v.length() > 0) out.append(key).append(" ").append(v).append("\n");
  }

  private static void emitList(StringBuilder out, String key, Vect v) {
    for (int i = 0; i < v.size(); i++) {
      out.append(key).append(" ").append(v.elementAt(i)).append("\n");
    }
  }

  /** A constant line is [lhs(String), arg(IValue)*, value(IValue)]. */
  private static String renderLine(Vect line) {
    StringBuilder b = new StringBuilder();
    b.append(line.elementAt(0));            // lhs symbol path
    int n = line.size();
    if (n > 2) {                            // operator-argument form op(a,b)
      b.append(" ( ");
      for (int i = 1; i < n - 1; i++) {
        if (i > 1) b.append(" , ");
        b.append(((IValue) line.elementAt(i)).toString());
      }
      b.append(" )");
    }
    b.append(" = ").append(((IValue) line.elementAt(n - 1)).toString());
    return b.toString();
  }
}
