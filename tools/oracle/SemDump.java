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
 * not expanded). Volatile UIDs are omitted; the `level` field is omitted
 * because level checking is unit 7. Spans are begin.line.col-end.line.col,
 * or ~ for a synthesized (locationless) node.
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
      SanySettings settings = SanySettings.validAstSettings();
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
    System.out.print(out);
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
        for (int i = 0; i < bq.length; i++) {
          for (FormalParamNode p : bq[i]) {
            indent(d + 1, o);
            o.append("bound ").append(p.getName()).append(' ').append(sll(p)).append('\n');
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
