import tla2sany.drivers.SANY;
import tla2sany.drivers.SanyExitCode;
import tla2sany.drivers.SanySettings;
import tla2sany.modanalyzer.SpecObj;
import tla2sany.output.LogLevel;
import tla2sany.output.SimpleSanyOutput;
import tla2sany.output.SanyOutput;
import tla2sany.semantic.*;
import tla2sany.st.Location;
import util.SimpleFilenameToStream;
import util.ToolIO;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

/**
 * Dumps a normalized SANY semantic graph for differential unit-6 testing.
 *
 * ACCEPT followed by the root module's semantic tree, preorder, two-space
 * indent, then a DIAGS section (semantic error/abort messages in report
 * order); or REJECT alone when the front end fails before producing a
 * root module.
 *
 * The tree is restricted to declarations/definitions originating in the
 * root module (imported ops from EXTENDS/INSTANCE are referenced by name,
 * not expanded). Volatile UIDs are omitted. Each node carries its
 * post-levelCheck L<level> (L-1 when level checking never ran). Spans are
 * begin.line.col-end.line.col, or ~ for a synthesized (locationless) node.
 *
 * After DIAGS a LEVELS section projects the level-constraint machinery
 * (unit 4): one sorted line per root-module definition and one for the
 * module node, carrying max-levels, weights, higher-order min-max/level
 * conditions, level params, level constraints, arg-level constraints,
 * arg-level params, and non-Leibniz params. gen-sem-tests.py splits this
 * section into golden-lvl.txt (oracle-only until the Hoon renderer emits
 * the same projection).
 */
public final class SemDump {

  public static void main(String[] args) throws Exception {
    String path = args[0];
    ByteArrayOutputStream errBuf = new ByteArrayOutputStream();
    PrintStream errPs = new PrintStream(errBuf, true, "UTF-8");
    SpecObj spec = new SpecObj(path, new SimpleFilenameToStream());
    ModuleNode root = null;
    try {
      SanyOutput so = new SimpleSanyOutput(errPs, LogLevel.ERROR);
      // semantic analysis + level checking + linting, no PlusCal validation
      SanySettings settings = new SanySettings(true, true, true, false);
      SANY.parse(spec, path, so, settings);
      ExternalModuleTable emt = spec.getExternalModuleTable();
      if (emt != null) {
        root = emt.getRootModule();
      }
    } catch (Throwable t) {
      root = null;
    }
    StringBuilder out = new StringBuilder();
    if (root == null) {
      System.out.print("REJECT\n");
      return;
    }
    out.append("ACCEPT\n");
    module(root, 0, out);
    // DIAGS: the semantic Errors channel, in report order, one line per
    // message: D <numeric-code> <severity> <loc> <first-line-of-message>
    java.util.List<Errors.ErrorDetails> msgs = spec.semanticErrors.getMessages();
    if (!msgs.isEmpty()) {
      out.append("DIAGS\n");
      for (Errors.ErrorDetails ed : msgs) {
        Location l = ed.getLocation();
        String locs = (l == null) ? "~"
            : l.beginLine() + "." + l.beginColumn()
              + "-" + l.endLine() + "." + l.endColumn();
        String msg = ed.getMessage();
        int nl = msg.indexOf('\n');
        if (nl >= 0) msg = msg.substring(0, nl);
        out.append("D ").append(ed.getCode().getStandardValue())
           .append(' ').append(ed.getCode().getSeverityLevel())
           .append(' ').append(locs)
           .append(' ').append(esc(msg)).append('\n');
      }
    }
    // LEVELS: per-def level-constraint projection (unit 4). One line per
    // root-module OpDefNode plus one for the module itself, reading the
    // public LevelNode collection fields directly (no levelChecked
    // assertions), every collection sorted lexicographically so the
    // volatile HashSet/HashMap iteration order never reaches the golden.
    StringBuilder lv = new StringBuilder();
    levelsModule(root, lv);
    if (lv.length() > 0) {
      out.append("LEVELS\n").append(lv);
    }
    System.out.print(out);
  }

  private static void levelsModule(ModuleNode m, StringBuilder o) {
    lvlLine("MODULE " + m.getName(), m, null, o);
    for (OpDefNode def : m.getOpDefs()) {
      if (def.getOriginallyDefinedInModuleNode() != m) continue;
      lvlLine(def.getName().toString(), def, def, o);
    }
    for (ThmOrAssumpDefNode td : m.getThmOrAssDefs()) {
      if (td.getOriginallyDefinedInModuleNode() != m) continue;
      lvlLine(td.getName().toString(), td, null, o);
    }
    for (ModuleNode inner : m.getInnerModules()) {
      levelsModule(inner, o);
    }
  }

  private static java.util.List<String> sorted(java.util.Collection<String> c) {
    java.util.List<String> l = new java.util.ArrayList<>(c);
    java.util.Collections.sort(l);
    return l;
  }

  private static String join(java.util.List<String> l) {
    return String.join(",", l);
  }

  private static void lvlLine(String name, LevelNode ln, OpDefNode def, StringBuilder o) {
    try {
      StringBuilder b = new StringBuilder();
      b.append("lvl ").append(name).append(" L").append(level(ln));
      if (def != null && def.getArity() > 0) {
        try {
          StringBuilder ml = new StringBuilder();
          StringBuilder w = new StringBuilder();
          for (int i = 0; i < def.getArity(); i++) {
            if (i > 0) { ml.append(','); w.append(','); }
            ml.append(def.getMaxLevel(i));
            w.append(def.getWeight(i));
          }
          b.append(" ml=[").append(ml).append("] w=[").append(w).append(']');
        } catch (Throwable t) {
          b.append(" ml=? w=?");
        }
        // higher-order data only when some parameter is itself an operator
        FormalParamNode[] ps = def.getParams();
        boolean ho = false;
        for (FormalParamNode p : ps) if (p.getArity() > 0) ho = true;
        if (ho) {
          try {
            StringBuilder mml = new StringBuilder();
            StringBuilder olc = new StringBuilder();
            for (int i = 0; i < ps.length; i++) {
              if (i > 0) { mml.append(';'); olc.append(';'); }
              for (int j = 0; j < ps[i].getArity(); j++) {
                if (j > 0) mml.append(',');
                mml.append(def.getMinMaxLevel(i, j));
              }
              for (int j = 0; j < ps.length; j++) {
                for (int k = 0; k < ps[i].getArity(); k++) {
                  olc.append(def.getOpLevelCond(i, j, k) ? 'T' : 'F');
                }
              }
            }
            b.append(" mml=[").append(mml).append("] olc=[").append(olc).append(']');
          } catch (Throwable t) {
            b.append(" mml=? olc=?");
          }
        }
      }
      java.util.List<String> lp = new java.util.ArrayList<>();
      for (SymbolNode s : ln.levelParams) lp.add(s.getName().toString());
      if (!lp.isEmpty()) b.append(" lp={").append(join(sorted(lp))).append('}');
      java.util.List<String> lc = new java.util.ArrayList<>();
      for (java.util.Map.Entry<SymbolNode, Integer> e
             : ((java.util.Map<SymbolNode, Integer>) ln.levelConstraints).entrySet()) {
        lc.add(e.getKey().getName() + "<=" + e.getValue());
      }
      if (!lc.isEmpty()) b.append(" lc={").append(join(sorted(lc))).append('}');
      java.util.List<String> alc = new java.util.ArrayList<>();
      for (Object e : ((java.util.Map) ln.argLevelConstraints).entrySet()) {
        java.util.Map.Entry<?, ?> en = (java.util.Map.Entry<?, ?>) e;
        alc.add(LevelProbe.pap(en.getKey()) + ">=" + en.getValue());
      }
      if (!alc.isEmpty()) b.append(" alc={").append(join(sorted(alc))).append('}');
      java.util.List<String> alp = new java.util.ArrayList<>();
      for (Object a : ln.argLevelParams) alp.add(LevelProbe.alp(a));
      if (!alp.isEmpty()) b.append(" alp={").append(join(sorted(alp))).append('}');
      java.util.List<String> nlp = new java.util.ArrayList<>();
      for (SymbolNode s : ln.nonLeibnizParams) nlp.add(s.getName().toString());
      if (!nlp.isEmpty()) b.append(" nlp={").append(join(sorted(nlp))).append('}');
      o.append(b).append('\n');
    } catch (Throwable t) {
      o.append("lvl ").append(name).append(" ?\n");
    }
  }

  private static void indent(int d, StringBuilder o) {
    for (int i = 0; i < d; i++) o.append("  ");
  }

  private static String loc(SemanticNode n) {
    Location l = n.getLocation();
    if (l == null || l.beginLine() == Integer.MAX_VALUE
        || l.beginLine() == Integer.MIN_VALUE) {
      return "~";
    }
    return l.beginLine() + "." + l.beginColumn()
         + "-" + l.endLine() + "." + l.endColumn();
  }

  private static int level(SemanticNode n) {
    try { return ((tla2sany.semantic.LevelNode) n).getLevel(); } catch (Throwable t) { return -1; }
  }

  private static String sll(SemanticNode n) {
    return "L" + level(n) + " " + loc(n);
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

  private static void module(ModuleNode m, int d, StringBuilder o) {
    indent(d, o);
    o.append("MODULE ").append(m.getName()).append(' ').append(loc(m)).append('\n');
    for (OpDeclNode c : m.getConstantDecls()) {
      indent(d + 1, o);
      o.append("const ").append(c.getName()).append(" arity=").append(c.getArity())
       .append(' ').append(sll(c)).append('\n');
    }
    for (OpDeclNode v : m.getVariableDecls()) {
      indent(d + 1, o);
      o.append("var ").append(v.getName()).append(' ').append(sll(v)).append('\n');
    }
    for (OpDefNode def : m.getOpDefs()) {
      if (def.getOriginallyDefinedInModuleNode() != m) continue;
      opdef(def, d + 1, o);
    }
    for (ThmOrAssumpDefNode td : m.getThmOrAssDefs()) {
      if (td.getOriginallyDefinedInModuleNode() != m) continue;
      indent(d + 1, o);
      o.append("thmdef ").append(td.getName()).append(" local=")
       .append(td.isLocal() ? "y" : "n").append(' ').append(sll(td)).append('\n');
      node(td.getBody(), d + 2, o);
    }
    for (AssumeNode a : m.getAssumptions()) {
      indent(d + 1, o);
      o.append("assume");
      if (a.getDef() != null) o.append(" name=").append(a.getDef().getName());
      o.append(' ').append(sll(a)).append('\n');
      node(a.getAssume(), d + 2, o);
    }
    for (TheoremNode t : m.getTheorems()) {
      indent(d + 1, o);
      o.append("theorem");
      if (t.getName() != null) o.append(" name=").append(t.getName());
      o.append(' ').append(sll(t)).append('\n');
      node(t.getTheorem(), d + 2, o);
    }
    for (InstanceNode in : m.getInstances()) {
      indent(d + 1, o);
      o.append("instance");
      if (in.getName() != null) o.append(" name=").append(in.getName());
      o.append(" module=").append(in.getModule().getName())
       .append(" local=").append(in.getLocal() ? "y" : "n")
       .append(' ').append(sll(in)).append('\n');
    }
    for (ModuleNode inner : m.getInnerModules()) {
      module(inner, d + 1, o);
    }
  }

  private static void opdef(OpDefNode def, int d, StringBuilder o) {
    indent(d, o);
    o.append("def ").append(def.getName())
     .append(" arity=").append(def.getArity())
     .append(" local=").append(def.isLocal() ? "y" : "n")
     .append(' ').append(sll(def)).append('\n');
    for (FormalParamNode p : def.getParams()) {
      indent(d + 1, o);
      o.append("param ").append(p.getName()).append(" arity=").append(p.getArity())
       .append(' ').append(sll(p)).append('\n');
    }
    if (def.getBody() != null) node(def.getBody(), d + 1, o);
  }

  private static void node(SemanticNode n, int d, StringBuilder o) {
    if (n == null) {
      indent(d, o);
      o.append("<null>\n");
      return;
    }
    if (n instanceof OpApplNode) {
      OpApplNode a = (OpApplNode) n;
      indent(d, o);
      SymbolNode op = a.getOperator();
      o.append("apply ").append(op.getName())
       .append(" opkind=").append(kindName(op.getKind()))
       .append(' ').append(sll(a)).append('\n');
      FormalParamNode[] unb = a.getUnbdedQuantSymbols();
      if (unb != null) {
        for (FormalParamNode p : unb) {
          indent(d + 1, o);
          o.append("ubound ").append(p.getName()).append(' ').append(sll(p)).append('\n');
        }
      }
      FormalParamNode[][] bq = a.getBdedQuantSymbolLists();
      if (bq != null) {
        ExprNode[] bounds = a.getBdedQuantBounds();
        // R1.3.8(b): whether each group is a TUPLE pattern (`<<i, j>> \in S`)
        // rather than a plain list (`i, j \in S`). The two mean different
        // things -- destructure one element vs range each variable over the
        // whole set -- and without this the projection cannot tell them apart,
        // so a port could not be measured against the distinction at all.
        boolean[] tup = a.isBdedQuantATuple();
        for (int i = 0; i < bq.length; i++) {
          boolean isTup = tup != null && i < tup.length && tup[i];
          for (FormalParamNode p : bq[i]) {
            indent(d + 1, o);
            o.append("bound ").append(p.getName()).append(' ').append(sll(p));
            if (isTup) o.append(" tup");
            o.append('\n');
          }
          if (bounds != null && i < bounds.length) node(bounds[i], d + 2, o);
        }
      }
      for (ExprOrOpArgNode arg : a.getArgs()) node(arg, d + 1, o);
      return;
    }
    if (n instanceof NumeralNode) {
      indent(d, o);
      o.append("num ").append(((NumeralNode) n).val()).append(' ').append(sll(n)).append('\n');
      return;
    }
    if (n instanceof DecimalNode) {
      indent(d, o);
      o.append("dec ").append(((DecimalNode) n).bigVal().toString()).append(' ').append(sll(n)).append('\n');
      return;
    }
    if (n instanceof StringNode) {
      indent(d, o);
      o.append("str ").append(esc(((StringNode) n).getRep().toString())).append(' ').append(sll(n)).append('\n');
      return;
    }
    if (n instanceof AtNode) {
      indent(d, o);
      o.append("at ").append(sll(n)).append('\n');
      return;
    }
    if (n instanceof OpArgNode) {
      OpArgNode oa = (OpArgNode) n;
      indent(d, o);
      o.append("oparg ").append(oa.getName());
      if (oa.getOp() != null) o.append(" op=").append(oa.getOp().getName());
      o.append(" arity=").append(oa.getArity()).append(' ').append(sll(n)).append('\n');
      return;
    }
    if (n instanceof LetInNode) {
      LetInNode li = (LetInNode) n;
      indent(d, o);
      o.append("letin lets=").append(li.getLets().length).append(' ').append(sll(n)).append('\n');
      for (OpDefNode ld : li.getLets()) opdef(ld, d + 1, o);
      indent(d + 1, o);
      o.append("in\n");
      node(li.getBody(), d + 2, o);
      return;
    }
    if (n instanceof SubstInNode) {
      SubstInNode si = (SubstInNode) n;
      indent(d, o);
      o.append("substin subs=").append(si.getSubsts().length).append(' ').append(sll(n)).append('\n');
      for (Subst s : si.getSubsts()) {
        indent(d + 1, o);
        o.append("sub ").append(s.getOp().getName()).append(" <-\n");
        node(s.getExpr(), d + 2, o);
      }
      indent(d + 1, o);
      o.append("in\n");
      node(si.getBody(), d + 2, o);
      return;
    }
    if (n instanceof APSubstInNode) {
      APSubstInNode si = (APSubstInNode) n;
      indent(d, o);
      o.append("apsubstin subs=").append(si.getSubsts().length).append(' ').append(sll(n)).append('\n');
      for (Subst s : si.getSubsts()) {
        indent(d + 1, o);
        o.append("sub ").append(s.getOp().getName()).append(" <-\n");
        node(s.getExpr(), d + 2, o);
      }
      indent(d + 1, o);
      o.append("in\n");
      node(si.getBody(), d + 2, o);
      return;
    }
    if (n instanceof LabelNode) {
      LabelNode lb = (LabelNode) n;
      indent(d, o);
      o.append("label ").append(lb.getName()).append(' ').append(sll(n)).append('\n');
      node(lb.getBody(), d + 1, o);
      return;
    }
    if (n instanceof AssumeProveNode) {
      AssumeProveNode ap = (AssumeProveNode) n;
      indent(d, o);
      o.append("assumeprove ").append(sll(n)).append('\n');
      for (SemanticNode as : ap.getAssumes()) node(as, d + 1, o);
      indent(d + 1, o);
      o.append("prove\n");
      node(ap.getProve(), d + 2, o);
      return;
    }
    if (n instanceof NewSymbNode) {
      NewSymbNode ns = (NewSymbNode) n;
      indent(d, o);
      o.append("newsymb ").append(ns.getOpDeclNode().getName()).append(' ').append(sll(n)).append('\n');
      return;
    }
    // fallback: class name + generic children
    indent(d, o);
    String cn = n.getClass().getSimpleName();
    o.append("?").append(cn).append(' ').append(sll(n)).append('\n');
    SemanticNode[] kids = n.getChildren();
    if (kids != null) for (SemanticNode k : kids) node(k, d + 1, o);
  }

  private static String kindName(int k) {
    if (k >= 0 && k < ASTConstants.kinds.length && ASTConstants.kinds[k] != null) {
      return ASTConstants.kinds[k];
    }
    return "k" + k;
  }
}
