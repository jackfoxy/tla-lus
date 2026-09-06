import tlc2.tool.Action;
import tlc2.tool.StateVec;
import tlc2.tool.TLCState;
import tlc2.tool.impl.FastTool;
import util.SimpleFilenameToStream;
import util.ToolIO;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Ordered init/next STATE STREAM oracle (Work Unit 7 / R1.5.10).
 *
 * Usage: StreamDump <base>      (cwd holds <base>.tla and <base>.cfg)
 *
 * `tlc-safety-stategen`'s residue was that the port's state streams keep
 * branch/binding order but were only spot-tested — never differentially
 * compared. This projects exactly what Tool.getInitStates / getNextStates
 * return, IN ORDER, so the Hoon +solve streams can be byte-compared:
 *
 *   STREAM
 *   INIT <count>
 *   S <i> <var=value; var=value; ...>     (declaration order, one line/state)
 *   ENDINIT
 *   NEXT <state-index> <count>
 *   S <i> <...>
 *   ENDNEXT
 *   ...
 *
 * Successor streams are emitted per (initial state x action) in Tool.getActions
 * order — the same nesting getNextStates drives — so a divergence in branch
 * order, \E element order, or partial-next threading shows up as a line diff,
 * not just a count mismatch. State rendering is normalized (one line, vars in
 * TLCState declaration order) so it is free of TLC's console formatting.
 */
public final class StreamDump {

  /** one-line, declaration-ordered rendering of a state's assigned variables */
  private static String render(TLCState s) {
    String raw = s.toString();            // "var = val\n..." (TLC's own order)
    List<String> parts = new ArrayList<>();
    for (String line : raw.split("\n")) {
      String t = line.trim();
      if (t.startsWith("/\\")) t = t.substring(2).trim();   // TLC renders conjuncts
      if (!t.isEmpty()) parts.add(t.replaceAll("\\s+", " "));
    }
    return String.join("; ", parts);
  }

  public static void main(String[] args) throws Exception {
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    String base = args[0];

    FastTool tool = new FastTool(base, base, new SimpleFilenameToStream());
    StringBuilder out = new StringBuilder();
    out.append("STREAM\n");

    StateVec init = tool.getInitStates();
    out.append("INIT ").append(init.size()).append("\n");
    for (int i = 0; i < init.size(); i++) {
      out.append("S ").append(i).append(" ").append(render(init.elementAt(i))).append("\n");
    }
    out.append("ENDINIT\n");

    // Successors of each initial state, concatenated over getActions() in
    // action order — exactly the sequence ModelChecker.doNext walks, and the
    // sequence the Hoon +solve-next produces for the whole Next (a `\/`
    // branches in source order). Action DECOMPOSITION itself is
    // tlc-safety-trace's projection, so it is not baked into this golden.
    Action[] acts = tool.getActions();
    for (int si = 0; si < init.size(); si++) {
      TLCState s = init.elementAt(si);
      List<String> succ = new ArrayList<>();
      for (int ai = 0; ai < acts.length; ai++) {
        StateVec nx = tool.getNextStates(acts[ai], s);
        for (int i = 0; i < nx.size(); i++) succ.add(render(nx.elementAt(i)));
      }
      out.append("NEXT ").append(si).append(" ").append(succ.size()).append("\n");
      for (int i = 0; i < succ.size(); i++) {
        out.append("S ").append(i).append(" ").append(succ.get(i)).append("\n");
      }
      out.append("ENDNEXT\n");
    }
    System.out.print(out);
  }
}
