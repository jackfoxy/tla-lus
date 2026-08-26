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
 * Single-worker safety model-checking oracle for Work Unit 7.
 *
 * Usage: SafetyDump <base> [extra tlc args...]
 *   (cwd holds <base>.tla and <base>.cfg)
 *
 * Drives tlc2.TLC with a single deterministic worker and an
 * IMessagePrinterRecorder, then projects the safety-relevant behaviour that the
 * Hoon checker must match, free of timings, worker ids, disk layout, and text
 * formatting incidental to the console renderer:
 *
 *   SAFETY
 *   VERDICT <ok|violated-invariant|violated-initial|deadlock|assumption-false|
 *            assumption-error|violated-property|error>
 *   EC <primary-error-code>          (0 when the run succeeded)
 *   INV <name>                       (invariant-violation verdicts only)
 *   STAT generated <n>
 *   STAT distinct <n>
 *   STAT queue <n>
 *   STAT depth <n>
 *   STAT outdegree <min> <mean> <p95> <max>   (success runs, when collected)
 *   COVERAGE <label>[: <A>:<B>]                (only with -coverage)
 *   TRACE <count>
 *   STATE <num> <fingerprint>
 *   LABEL <action name / initial predicate / back-to-state / stuttering>
 *   <state variable bindings, verbatim TLC rendering, one var per line>
 *   ENDSTATE
 *   ...
 *
 * Per-state fingerprints come straight from the TLC_STATE_PRINT2 metadata
 * (StatePrinter computes TLCStateInfo.fingerPrint() for every assigned trace
 * state), so the counterexample carries the exact FP64 values Work Unit 7.1
 * targets. Runs single-worker (-workers 1) with the default FP64 index (-fp 0)
 * so the fingerprints and BFS order are deterministic.
 */
public final class SafetyDump {

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

    StringBuilder out = new StringBuilder("SAFETY\n");
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
    if (has(EC.TLC_ASSUMPTION_FALSE)) { verdict = "assumption-false"; ec = EC.TLC_ASSUMPTION_FALSE; }
    else if (has(EC.TLC_ASSUMPTION_EVALUATION_ERROR)) { verdict = "assumption-error"; ec = EC.TLC_ASSUMPTION_EVALUATION_ERROR; }
    else if (has(EC.TLC_INVARIANT_VIOLATED_INITIAL)) { verdict = "violated-initial"; ec = EC.TLC_INVARIANT_VIOLATED_INITIAL; }
    else if (has(EC.TLC_INVARIANT_VIOLATED_BEHAVIOR)) { verdict = "violated-invariant"; ec = EC.TLC_INVARIANT_VIOLATED_BEHAVIOR; }
    else if (has(EC.TLC_INVARIANT_VIOLATED_LEVEL)) { verdict = "violated-invariant"; ec = EC.TLC_INVARIANT_VIOLATED_LEVEL; }
    else if (has(EC.TLC_DEADLOCK_REACHED)) { verdict = "deadlock"; ec = EC.TLC_DEADLOCK_REACHED; }
    else if (has(EC.TLC_TEMPORAL_PROPERTY_VIOLATED)) { verdict = "violated-property"; ec = EC.TLC_TEMPORAL_PROPERTY_VIOLATED; }
    else if (has(EC.TLC_SUCCESS)) { verdict = "ok"; ec = 0; }
    else { verdict = "error"; ec = firstErrorCode(); }

    out.append("VERDICT ").append(verdict).append("\n");
    out.append("EC ").append(ec).append("\n");

    // Invariant name, when reported.
    for (int code : new int[]{EC.TLC_INVARIANT_VIOLATED_BEHAVIOR,
                              EC.TLC_INVARIANT_VIOLATED_INITIAL,
                              EC.TLC_INVARIANT_VIOLATED_LEVEL}) {
      if (has(code)) { out.append("INV ").append(arg(code, 0, 0)).append("\n"); break; }
    }

    // Statistics.
    if (has(EC.TLC_STATS)) {
      Object[] s = last(EC.TLC_STATS);
      String[] ss = (String[]) s;
      out.append("STAT generated ").append(ss[0]).append("\n");
      out.append("STAT distinct ").append(ss[1]).append("\n");
      out.append("STAT queue ").append(ss[2]).append("\n");
    }
    if (has(EC.TLC_SEARCH_DEPTH)) {
      out.append("STAT depth ").append(arg(EC.TLC_SEARCH_DEPTH, 0, 0)).append("\n");
    }
    if (has(EC.TLC_STATE_GRAPH_OUTDEGREE)) {
      String[] od = (String[]) last(EC.TLC_STATE_GRAPH_OUTDEGREE);
      out.append("STAT outdegree ").append(od[0]).append(" ").append(od[1])
         .append(" ").append(od[2]).append(" ").append(od[3]).append("\n");
    }

    // Coverage (only present when -coverage was requested).
    //
    // R2.7.4.2b widened this from "INIT/NEXT, argument index 2" to the WHOLE
    // reportable block, rendered exactly as MP renders it, so the Hoon side can
    // be compared line for line rather than number by number:
    //
    //   TLC_COVERAGE_INIT/NEXT/CONSTRAINT -> "%1%: %2%:%3%"
    //   TLC_COVERAGE_PROPERTY             -> "%1%"          (invariants; no counts)
    //
    // The per-code lists are emitted in CostModelCreator.report()'s own order --
    // INIT, then the NEXT actions (sorted by the action's span), then the
    // invariants, then the action constraints followed by the state constraints,
    // both of which are TLC_COVERAGE_CONSTRAINT and keep their emission order
    // inside that list. So walking the codes in this fixed sequence reproduces
    // the block's order without needing a global emission clock.
    //
    // Deliberately NOT projected, and declared as approved differences: the
    // per-VARIABLE TLC_COVERAGE_VAR line (a HyperLogLog estimate) and the
    // indented per-node TLC_COVERAGE_VALUE / _COST sub-expression lines.
    for (int code : new int[]{EC.TLC_COVERAGE_INIT, EC.TLC_COVERAGE_NEXT}) {
      for (Object o : REC.getOrDefault(code, new ArrayList<>())) {
        String[] c = (String[]) o;
        out.append("COVERAGE ").append(c[0]).append(": ")
           .append(c[1]).append(":").append(c[2]).append("\n");
      }
    }
    for (Object o : REC.getOrDefault(EC.TLC_COVERAGE_PROPERTY, new ArrayList<>())) {
      String[] c = (String[]) o;
      out.append("COVERAGE ").append(c[0]).append("\n");
    }
    for (Object o : REC.getOrDefault(EC.TLC_COVERAGE_CONSTRAINT, new ArrayList<>())) {
      String[] c = (String[]) o;
      out.append("COVERAGE ").append(c[0]).append(": ")
         .append(c[1]).append(":").append(c[2]).append("\n");
    }

    // Counterexample trace, in generation order, with per-state fingerprints.
    // TLC_STATE_PRINT2 records the TLCStateInfo object and the ordinal, from
    // which the action label, variable bindings, and FP64 fingerprint derive.
    List<Object> states = REC.getOrDefault(EC.TLC_STATE_PRINT2, new ArrayList<>());
    boolean stutter = has(EC.TLC_STATE_PRINT3);
    boolean lasso = has(EC.TLC_BACK_TO_STATE);

    // An initial-state invariant violation embeds the offending state in the
    // error record's second argument (no separate STATE_PRINT2); render it as
    // the length-1 trace. The fingerprint is not carried in that record.
    if (states.isEmpty() && has(EC.TLC_INVARIANT_VIOLATED_INITIAL)) {
      String stateString = arg(EC.TLC_INVARIANT_VIOLATED_INITIAL, 0, 1);
      out.append("TRACE 1\n");
      out.append("STATE 1 -1\nLABEL <Initial predicate>\n");
      for (String line : stateString.split("\n")) {
        if (!line.isEmpty()) out.append(line).append("\n");
      }
      out.append("ENDSTATE\n");
      System.out.print(out);
      return;
    }

    out.append("TRACE ").append(states.size() + (stutter || lasso ? 1 : 0)).append("\n");
    for (Object o : states) {
      Object[] r = (Object[]) o;              // [TLCStateInfo, Integer num]
      TLCStateInfo si = (TLCStateInfo) r[0];
      // Unsigned 64-bit hex, matching the @ux fingerprint Work Unit 7.1 emits.
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
      Object[] r = (Object[]) last(EC.TLC_BACK_TO_STATE);
      out.append("STATE ").append(r[1]).append(" -1\n");
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

  // The lowest-numbered recorded error code (2000+), used as the verdict code
  // for evaluation and other failures that are not one of the safety verdicts.
  private static int firstErrorCode() {
    int best = EC.GENERAL;
    for (int code : REC.keySet()) {
      if (code >= 2100 && code < best) best = code;
    }
    return best;
  }
}
