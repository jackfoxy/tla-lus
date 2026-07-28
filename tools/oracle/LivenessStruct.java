import tlc2.tool.impl.FastTool;
import tlc2.tool.liveness.Liveness;
import tlc2.tool.liveness.OrderOfSolution;
import tlc2.tool.liveness.LiveExprNode;
import util.SimpleFilenameToStream;
import util.ToolIO;

/**
 * Structural projection of TLC's temporal-property normalization, for the
 * Work Unit 8.1 differential (live-expression / OrderOfSolution decomposition).
 *
 * Usage: LivenessStruct <base>   (cwd holds <base>.tla and <base>.cfg)
 *
 * Builds a FastTool (SANY analyze + SpecProcessor, so SPECIFICATION fairness
 * and PROPERTY temporals are in scope), then runs Liveness.processLiveness to
 * obtain the OrderOfSolution[] — the normalized (simplify + toDNF + pushNeg)
 * decomposition of `livespec /\ -livecheck` into disjuncts, each with a tableau
 * formula, promises, and the checkState/checkAction bins the PossibleErrorModels
 * index into. The projection is what lib/temporal.hoon must reproduce:
 *
 *   LIVESTRUCT
 *   OOS <count>                       (number of OrderOfSolutions)
 *   --- <i> ---
 *   PROMISES <n>
 *   CHECKSTATE <n>
 *   CHECKACTION <n>
 *   PEMS <n>
 *   TABLEAU <node-count>              (built here; the graph itself is unit 8.2)
 *   TF
 *   <OrderOfSolution.toString(), the canonical padded rendering of the tableau
 *    formula and the pems over checkState/checkAction>
 *   ENDTF
 *   ...
 *
 * OrderOfSolution.toString() is TLC's own -livedebug rendering: stable for a
 * given spec, free of object identities and timings. Leaf state/action
 * predicates render via the semantic ExprNode, so the projection also pins the
 * leaf text lib/semantic must match.
 */
public final class LivenessStruct {

  public static void main(String[] args) {
    String base = args[0];
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    StringBuilder out = new StringBuilder("LIVESTRUCT\n");
    FastTool tool;
    try {
      tool = new FastTool(base, base, new SimpleFilenameToStream());
    } catch (Throwable t) {
      out.append("LOAD ! ").append(t.getClass().getSimpleName())
         .append(": ").append(msg(t)).append("\n");
      System.out.print(out);
      return;
    }

    OrderOfSolution[] oss;
    try {
      oss = Liveness.processLiveness(tool, true);
    } catch (Throwable t) {
      out.append("PROCESS ! ").append(t.getClass().getSimpleName())
         .append(": ").append(msg(t)).append("\n");
      System.out.print(out);
      return;
    }

    out.append("OOS ").append(oss.length).append("\n");
    for (int i = 0; i < oss.length; i++) {
      OrderOfSolution o = oss[i];
      out.append("--- ").append(i).append(" ---\n");
      Object[] proms = o.getPromises();   // LNEven[] is package-private; view as Object[]
      out.append("PROMISES ").append(proms == null ? 0 : proms.length).append("\n");
      out.append("CHECKSTATE ").append(o.getCheckState() == null ? 0 : o.getCheckState().length).append("\n");
      out.append("CHECKACTION ").append(o.getCheckAction() == null ? 0 : o.getCheckAction().length).append("\n");
      out.append("PEMS ").append(o.getPems() == null ? 0 : o.getPems().length).append("\n");
      out.append("TABLEAU ").append(o.hasTableau() ? o.getTableau().size() : 0).append("\n");
      out.append("TF\n").append(o.toString());
      if (!o.toString().endsWith("\n")) out.append("\n");
      out.append("ENDTF\n");
    }
    System.out.print(out);
  }

  private static String msg(Throwable t) {
    String m = t.getMessage();
    if (m == null) return "";
    return m.replace("\n", " ").trim();
  }
}
