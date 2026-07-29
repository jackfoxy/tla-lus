import tlc2.tool.Action;
import tlc2.tool.TLCState;
import tlc2.tool.impl.FastTool;
import tlc2.tool.liveness.LiveCheck;
import tlc2.tool.liveness.OrderOfSolution;
import tlc2.tool.liveness.Liveness;
import tlc2.tool.liveness.AbstractDiskGraph;
import tlc2.util.FP64;
import tlc2.util.LongVec;
import tlc2.util.SetOfStates;
import tlc2.tool.StateVec;
import tlc2.util.statistics.DummyBucketStatistics;
import tlc2.value.RandomEnumerableValues;
import util.SimpleFilenameToStream;
import util.ToolIO;

import java.nio.file.Files;
import java.util.HashSet;
import java.util.ArrayDeque;
import java.util.Set;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Projects the behavior-graph PRODUCT (LiveCheck's per-OrderOfSolution graph:
 * the reachable state graph paired with the tableau) for the unit 8.3
 * differential. Drives a FastTool (SANY + SpecProcessor) and feeds the reachable
 * states to a standalone LiveCheck exactly as ModelChecker does
 * (addInitState / addNextState), then projects, per OrderOfSolution, the product
 * node count and the initial-node count. Deterministic per fixture (a set, not
 * a run-order artifact); no timings, workers, or disk layout.
 *
 * Output:
 *   PRODUCT
 *   OOS <n>
 *   --- <i> ---
 *   NODES <product node count>
 *   INITS <initial product node count>
 */
public final class ProductDump {

  public static void main(String[] args) throws Exception {
    final String base = args[0];
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    FP64.Init(0);
    RandomEnumerableValues.setSeed(0L);

    final StringBuilder out = new StringBuilder("PRODUCT\n");
    final FastTool tool;
    try {
      tool = new FastTool(base, base, new SimpleFilenameToStream());
    } catch (Throwable t) {
      out.append("LOAD ! ").append(t.getClass().getSimpleName()).append(": ").append(t.getMessage()).append("\n");
      System.out.print(out);
      return;
    }

    final OrderOfSolution[] oss;
    try {
      oss = Liveness.processLiveness(tool, true);
    } catch (Throwable t) {
      out.append("PROCESS ! ").append(t.getClass().getSimpleName()).append(": ").append(t.getMessage()).append("\n");
      System.out.print(out);
      return;
    }

    final String mdir = Files.createTempDirectory("proddump").toString();
    final LiveCheck lc = new LiveCheck(tool, oss, mdir, new DummyBucketStatistics());

    // Feed the reachable state graph to LiveCheck in BFS order, exactly as
    // ModelChecker does: init states then, per dequeued state, its next states.
    final Map<Long, TLCState> byFp = new LinkedHashMap<>();
    final ArrayDeque<Long> queue = new ArrayDeque<>();

    final StateVec inits = tool.getInitStates();
    for (int i = 0; i < inits.size(); i++) {
      final TLCState s = inits.elementAt(i);
      final long fp = s.fingerPrint();
      lc.addInitState(tool, s, fp);
      if (!byFp.containsKey(fp)) {
        byFp.put(fp, s);
        queue.add(fp);
      }
    }

    final Action[] actions = tool.getActions();
    while (!queue.isEmpty()) {
      final long fp0 = queue.poll();
      final TLCState s0 = byFp.get(fp0);
      final SetOfStates nextStates = new SetOfStates();
      for (final Action act : actions) {
        final StateVec sv = tool.getNextStates(act, s0);
        for (int j = 0; j < sv.size(); j++) {
          final TLCState s1 = sv.elementAt(j);
          nextStates.put(s1.fingerPrint(), s1);
        }
      }
      lc.addNextState(tool, s0, fp0, nextStates);
      for (int j = 0; j < nextStates.size(); j++) {
        final TLCState s1 = nextStates.next();
        final long fp1 = s1.fingerPrint();
        if (!byFp.containsKey(fp1)) {
          byFp.put(fp1, s1);
          queue.add(fp1);
        }
      }
      nextStates.resetNext();
    }

    out.append("OOS ").append(oss.length).append("\n");
    for (int i = 0; i < oss.length; i++) {
      out.append("--- ").append(i).append(" ---\n");
      final OrderOfSolution o = oss[i];
      final AbstractDiskGraph g = lc.getChecker(i).getDiskGraph();
      final LongVec initNodes = g.getInitNodes();
      // A product node is a recorded (stateFP, tableauIdx) pair. size() counts
      // distinct fingerprints, not product nodes; count recorded (fp,tidx) via
      // getPtr (-1 == not recorded). tidx ranges over the tableau, or is -1 for
      // a no-tableau OrderOfSolution (the state graph alone).
      int nodes = 0;
      if (o.hasTableau()) {
        final int tsz = o.getTableau().size();
        for (final long fp : byFp.keySet()) {
          for (int t = 0; t < tsz; t++) {
            if (g.getPtr(fp, t) != -1) nodes++;
          }
        }
      } else {
        for (final long fp : byFp.keySet()) {
          if (g.getPtr(fp, -1) != -1) nodes++;
        }
      }
      out.append("NODES ").append(nodes).append("\n");
      out.append("INITS ").append(initNodes.size() / 2).append("\n");
    }
    System.out.print(out);
  }
}
