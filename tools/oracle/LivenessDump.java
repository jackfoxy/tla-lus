import tlc2.TLC;
import tlc2.TLCGlobals;
import tlc2.output.EC;
import tlc2.output.MP;
import tlc2.output.IMessagePrinterRecorder;
import tlc2.tool.TLCStateInfo;
import util.SimpleFilenameToStream;
import util.ToolIO;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Single-worker liveness (temporal-property) model-checking oracle for Work
 * Unit 8 (Phase C step C2).
 *
 * Usage: LivenessDump <base> [extra tlc args...]
 *   (cwd holds <base>.tla and <base>.cfg)
 *
 * Drives tlc2.TLC with a single deterministic worker and an
 * IMessagePrinterRecorder, then projects the liveness-relevant behaviour the
 * Hoon checker must match, free of timings, worker ids, thread order, and the
 * on-disk graph layout. The projection mirrors SafetyDump's shape, extended
 * with the temporal verdict, the violated property name(s), and the lasso's
 * loop target and stuttering / back-to-state classification:
 *
 *   LIVENESS
 *   VERDICT <ok|violated-property|error>
 *   EC <primary-error-code>          (0 when the run succeeded)
 *   WARN <code>                      (each printWarning code; 2279 = symmetry
 *                                     with liveness, which TLC warns about and
 *                                     continues — the port rejects it instead)
 *   PROP <name>                      (one line per violated property, in the
 *                                     order Liveness.findViolatedProperties
 *                                     yields them; violation verdicts only)
 *   STAT generated <n>
 *   STAT distinct <n>
 *   STAT queue <n>
 *   STAT depth <n>
 *   CLASS <stuttering|back-to-state>   (violation only)
 *   LOOP <n>                           (violation only; the loop-target state
 *                                       number the lasso returns to)
 *   TRACE <count>
 *   STATE <num> <fingerprint>
 *   LABEL <action name / initial predicate / back-to-state / stuttering>
 *   <state variable bindings, verbatim TLC rendering, one var per line>
 *   ENDSTATE
 *   ...
 *
 * The trace states come from TLC_STATE_PRINT2 (the prefix and the cycle states
 * LiveWorker.printTrace emits via StatePrinter), each carrying its FP64
 * fingerprint, exactly as SafetyDump captures them. The lasso is closed by
 * either TLC_STATE_PRINT3 (a stuttering self-loop, "State N: Stuttering") or
 * TLC_BACK_TO_STATE (a genuine cycle, "Back to state N"); the loop target for a
 * back-to-state lasso is the state number recorded with that marker.
 *
 * Runs single-worker (-workers 1) with the default FP64 index (-fp 0) so the
 * fingerprints and search order are deterministic.
 */
public final class LivenessDump {

  private static final Map<Integer, List<Object>> REC = new LinkedHashMap<>();

  public static void main(String[] args) {
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));

    MP.setRecorder(new IMessagePrinterRecorder() {
      public void record(int code, Object... objects) {
        REC.computeIfAbsent(code, k -> new ArrayList<>()).add(objects);
      }
    });

    String base = args[0];
    List<String> a = new ArrayList<>();
    a.add("-workers"); a.add("1");
    a.add("-fp"); a.add("0");
    a.add("-checkpoint"); a.add("0");
    a.add("-cleanup");
    a.add("-noGenerateSpecTE");
    for (int i = 1; i < args.length; i++) a.add(args[i]);
    a.add(base);

    StringBuilder out = new StringBuilder("LIVENESS\n");
    try {
      TLC tlc = new TLC();
      tlc.setResolver(new SimpleFilenameToStream());
      if (!tlc.handleParameters(a.toArray(new String[0]))) {
        out.append("VERDICT error\nEC ").append(EC.GENERAL).append("\n");
        System.out.print(out);
        return;
      }
      TLCGlobals.setNumWorkers(1);
      tlc.process();
    } catch (Throwable t) {
      out.append("VERDICT error\nEC ").append(EC.GENERAL).append("\n");
      System.out.print(out);
      return;
    }

    int ec = 0;
    String verdict;
    if (has(EC.TLC_ASSUMPTION_FALSE)) { verdict = "error"; ec = EC.TLC_ASSUMPTION_FALSE; }
    else if (has(EC.TLC_ASSUMPTION_EVALUATION_ERROR)) { verdict = "error"; ec = EC.TLC_ASSUMPTION_EVALUATION_ERROR; }
    else if (has(EC.TLC_TEMPORAL_PROPERTY_VIOLATED)) { verdict = "violated-property"; ec = EC.TLC_TEMPORAL_PROPERTY_VIOLATED; }
    else if (has(EC.TLC_INVARIANT_VIOLATED_INITIAL)) { verdict = "error"; ec = EC.TLC_INVARIANT_VIOLATED_INITIAL; }
    else if (has(EC.TLC_INVARIANT_VIOLATED_BEHAVIOR)) { verdict = "error"; ec = EC.TLC_INVARIANT_VIOLATED_BEHAVIOR; }
    else if (has(EC.TLC_DEADLOCK_REACHED)) { verdict = "error"; ec = EC.TLC_DEADLOCK_REACHED; }
    else if (has(EC.TLC_SUCCESS)) { verdict = "ok"; ec = 0; }
    else { verdict = "error"; ec = firstErrorCode(); }

    out.append("VERDICT ").append(verdict).append("\n");
    out.append("EC ").append(ec).append("\n");

    // Feature warnings TLC raises without aborting. 2279 (symmetry declared
    // during liveness checking) is the one Work Unit 8 cares about: TLC warns
    // and continues — possibly missing violations — where the port issues a
    // typed rejection instead (an approved, documented difference).
    if (has(EC.TLC_FEATURE_UNSUPPORTED_LIVENESS_SYMMETRY)) {
      out.append("WARN ").append(EC.TLC_FEATURE_UNSUPPORTED_LIVENESS_SYMMETRY).append("\n");
    }

    // Violated property name(s), in the order findViolatedProperties yields.
    if (has(EC.TLC_TEMPORAL_PROPERTY_VIOLATED)) {
      Object[] r = (Object[]) REC.get(EC.TLC_TEMPORAL_PROPERTY_VIOLATED).get(0);
      if (r.length > 0 && r[0] instanceof String[]) {
        for (String p : (String[]) r[0]) out.append("PROP ").append(p).append("\n");
      }
    }

    // Statistics.
    if (has(EC.TLC_STATS)) {
      String[] ss = (String[]) last(EC.TLC_STATS);
      out.append("STAT generated ").append(ss[0]).append("\n");
      out.append("STAT distinct ").append(ss[1]).append("\n");
      out.append("STAT queue ").append(ss[2]).append("\n");
    }
    if (has(EC.TLC_SEARCH_DEPTH)) {
      out.append("STAT depth ").append(arg(EC.TLC_SEARCH_DEPTH, 0, 0)).append("\n");
    }

    // Lasso classification and loop target.
    boolean stutter = has(EC.TLC_STATE_PRINT3);
    boolean lasso = has(EC.TLC_BACK_TO_STATE);
    List<Object> states = REC.getOrDefault(EC.TLC_STATE_PRINT2, new ArrayList<>());
    if (has(EC.TLC_TEMPORAL_PROPERTY_VIOLATED)) {
      if (stutter) {
        out.append("CLASS stuttering\n");
        // The lasso stutters at the last real trace state; that state is the
        // loop target.
        out.append("LOOP ").append(states.size()).append("\n");
      } else if (lasso) {
        out.append("CLASS back-to-state\n");
        // printBackToState (outside -tool mode) records a String[]{ stateNum,
        // actionInfo }; the loop-target state number is index 0.
        out.append("LOOP ").append(arg(EC.TLC_BACK_TO_STATE, 0, 0)).append("\n");
      }
    }

    // Counterexample trace, in generation order, with per-state fingerprints,
    // identical in shape to SafetyDump's TRACE section.
    out.append("TRACE ").append(states.size() + (stutter || lasso ? 1 : 0)).append("\n");
    for (Object o : states) {
      Object[] r = (Object[]) o;              // [TLCStateInfo, Integer num]
      TLCStateInfo si = (TLCStateInfo) r[0];
      String fp = si.state != null && si.state.allAssigned()
                    ? "0x" + Long.toUnsignedString(si.fingerPrint(), 16) : "-1";
      out.append("STATE ").append(r[1]).append(" ").append(fp).append("\n");
      out.append("LABEL ").append(si.info).append("\n");
      if (si.state != null) {
        for (String line : si.state.toString().split("\n")) {
          if (!line.isEmpty()) out.append(line).append("\n");
        }
      }
      out.append("ENDSTATE\n");
    }
    if (stutter) {
      Object[] r = (Object[]) last(EC.TLC_STATE_PRINT3);
      out.append("STATE ").append(r[1]).append(" -1\n");
      out.append("LABEL Stuttering\nENDSTATE\n");
    } else if (lasso) {
      // String[]{ stateNum, actionInfo }; the loop-target number is index 0.
      out.append("STATE ").append(arg(EC.TLC_BACK_TO_STATE, 0, 0)).append(" -1\n");
      out.append("LABEL Back to state\nENDSTATE\n");
    }

    System.out.print(out);
  }

  private static boolean has(int code) { return REC.containsKey(code); }

  private static Object[] last(int code) {
    List<Object> l = REC.get(code);
    return (Object[]) l.get(l.size() - 1);
  }

  private static String arg(int code, int recIdx, int argIdx) {
    Object[] r = (Object[]) REC.get(code).get(recIdx);
    Object v = r[argIdx];
    if (v instanceof String[]) return ((String[]) v)[0];
    return String.valueOf(v);
  }

  private static int firstErrorCode() {
    int best = EC.GENERAL;
    for (int code : REC.keySet()) {
      if (code >= 2100 && code < best) best = code;
    }
    return best;
  }
}
