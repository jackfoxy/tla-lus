import tla2sany.parser.TLAplusParser;
import tla2sany.st.Location;
import tla2sany.st.SyntaxTreeConstants;
import tla2sany.st.TreeNode;

import java.io.FileInputStream;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.HashMap;
import java.util.Map;

/**
 * Dumps the SANY concrete syntax tree for differential parser testing.
 *
 * ACCEPT followed by one line per node, preorder, two-space indent:
 *   <kind-name> <bl>.<bc>-<el>.<ec>[ <image>]     (image on leaves only)
 * or REJECT alone when the parse fails.
 *
 * Node kind names come from SyntaxTreeConstants (N_*); leaf token kinds
 * from TLAplusParserConstants via the same kebab convention as TokenDump.
 */
public final class AstDump {

  private static final java.util.Set<String> STATES = java.util.Set.of(
      "DEFAULT", "PRAGMA", "SPEC", "IN_COMMENT", "EMBEDDED", "IN_EOL_COMMENT");

  public static void main(String[] args) throws Exception {
    byte[] bytes = new FileInputStream(args[0]).readAllBytes();
    TLAplusParser parser = new TLAplusParser(
        new tla2sany.output.SilentSanyOutput(), bytes);
    boolean ok;
    try {
      ok = parser.parse();
    } catch (Throwable t) {
      ok = false;
    }
    if (!ok) {
      System.out.println("REJECT");
      return;
    }
    Map<Integer, String> names = kindNames();
    StringBuilder out = new StringBuilder("ACCEPT\n");
    walk(parser.rootNode(), 0, names, out);
    System.out.print(out);
  }

  private static void walk(TreeNode n, int depth, Map<Integer, String> names,
                           StringBuilder out) {
    if (n == null) {
      return;
    }
    for (int i = 0; i < depth; i++) {
      out.append("  ");
    }
    String name = names.getOrDefault(n.getKind(), "k" + n.getKind());
    Location loc = n.getLocation();
    out.append(name).append(' ');
    if (loc == null || loc.beginLine() == Integer.MAX_VALUE) {
      out.append('~');            // synthesized empty node: no location
    } else {
      out.append(loc.beginLine()).append('.').append(loc.beginColumn())
         .append('-')
         .append(loc.endLine()).append('.').append(loc.endColumn());
    }
    TreeNode[] heirs = n.heirs();
    if (heirs.length == 0) {
      out.append(' ').append(esc(n.getImage()));
    }
    out.append('\n');
    for (TreeNode h : heirs) {
      walk(h, depth + 1, names, out);
    }
  }

  private static String esc(String s) {
    StringBuilder b = new StringBuilder();
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      switch (c) {
        case '\\': b.append("\\\\"); break;
        case '\n': b.append("\\n"); break;
        case '\r': b.append("\\r"); break;
        case '\t': b.append("\\t"); break;
        case '\f': b.append("\\f"); break;
        default: b.append(c);
      }
    }
    return b.toString();
  }

  private static Map<Integer, String> kindNames() throws Exception {
    Map<Integer, String> map = new HashMap<>();
    for (Field f : SyntaxTreeConstants.class.getFields()) {
      if (!Modifier.isStatic(f.getModifiers()) || f.getType() != int.class) {
        continue;
      }
      String kebab = f.getName().toLowerCase().replace('_', '-');
      while (kebab.startsWith("-")) {
        kebab = kebab.substring(1);
      }
      map.putIfAbsent(f.getInt(null), kebab);
    }
    for (Field f : tla2sany.parser.TLAplusParserConstants.class.getFields()) {
      if (!Modifier.isStatic(f.getModifiers()) || f.getType() != int.class
          || STATES.contains(f.getName())) {
        continue;
      }
      String kebab = f.getName().toLowerCase().replace('_', '-');
      while (kebab.startsWith("-")) {
        kebab = kebab.substring(1);
      }
      map.putIfAbsent(f.getInt(null), kebab);
    }
    return map;
  }
}
