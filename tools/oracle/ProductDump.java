import tlc2.tool.Action;
import tlc2.tool.TLCState;
import tlc2.tool.impl.FastTool;
import tlc2.tool.liveness.LiveCheck;
import tlc2.tool.liveness.OrderOfSolution;
import tlc2.tool.liveness.Liveness;
import tlc2.tool.liveness.AbstractDiskGraph;
import tlc2.tool.liveness.GraphNode;
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
 *   PNODE <fp-rank> <tidx> CS <checkState bits>
 *   PEDGE <fp-rank> <tidx> -> <fp-rank> <tidx> CA <checkAction bits>
 */
public final class ProductDump {

  private static int norm(final int tidx) {
    return tidx < 0 ? 0 : tidx;
  }

  private static String bits(final tlc2.tool.liveness.GraphNode gn, final int slen) {
    if (slen == 0) return "-";
    final StringBuilder b = new StringBuilder(slen);
    for (int i = 0; i < slen; i++) {
      b.append(gn.getCheckState(i) ? "1" : "0");
    }
    return b.toString();
  }

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

      // R1.6.2/.3: the product GRAPH, not just its counts -- per node its
      // checkState bits, and per outgoing edge its checkAction bits. State
      // fingerprints are projected as a RANK (the index in the ascending
      // unsigned ordering of the reachable state fingerprints) rather than
      // raw: both sides compute the same FP64 (tlc-fp is parity), so the rank
      // is identical on both, and a rank keeps the golden readable.
      final int slen = o.getCheckState() == null ? 0 : o.getCheckState().length;
      final int alen = o.getCheckAction() == null ? 0 : o.getCheckAction().length;
      final Long[] sorted = byFp.keySet().toArray(new Long[0]);
      java.util.Arrays.sort(sorted, (a, b) -> Long.compareUnsigned(a, b));
      final Map<Long, Integer> rank = new LinkedHashMap<>();
      for (int r = 0; r < sorted.length; r++) {
        rank.put(sorted[r], r);
      }
      final int tlo = o.hasTableau() ? 0 : -1;
      final int thi = o.hasTableau() ? o.getTableau().size() - 1 : -1;
      // tlc2 keys the single implicit node of a no-tableau product at -1; the
      // projection normalizes it to 0, which is how the port indexes it
      for (final Long fp : sorted) {
        for (int t = tlo; t <= thi; t++) {
          if (g.getPtr(fp, t) == -1) continue;
          final GraphNode gn = g.getNode(fp, t);
          out.append("PNODE ").append(rank.get(fp)).append(" ").append(norm(t))
             .append(" CS ").append(bits(gn, slen)).append("\n");
          // successors in the node's own order, then sorted, so the projection
          // is a SET and not a traversal artifact
          final java.util.List<long[]> keys = new java.util.ArrayList<>();
          final java.util.List<String> succs = new java.util.ArrayList<>();
          for (int k = 0; k < gn.succSize(); k++) {
            final StringBuilder b = new StringBuilder();
            final Integer r1 = rank.get(gn.getStateFP(k));
            final int t1 = norm(gn.getTidx(k));
            b.append(r1 == null ? -1 : r1).append(" ").append(t1).append(" CA ");
            if (alen == 0) {
              b.append("-");
            } else {
              for (int j = 0; j < alen; j++) {
                b.append(gn.getCheckAction(slen, alen, k, j) ? "1" : "0");
              }
            }
            succs.add(b.toString());
            keys.add(new long[] { r1 == null ? -1 : r1, t1, succs.size() - 1 });
          }
          // sort NUMERICALLY by (rank, tidx) -- a lexicographic sort of the
          // rendered strings would put rank 10 before rank 2
          keys.sort((a, b) -> a[0] != b[0] ? Long.compare(a[0], b[0]) : Long.compare(a[1], b[1]));
          for (final long[] k : keys) {
            out.append("PEDGE ").append(rank.get(fp)).append(" ").append(norm(t))
               .append(" -> ").append(succs.get((int) k[2])).append("\n");
          }
        }
      }
    }
    System.out.print(out);
  }
}
