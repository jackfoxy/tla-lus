import tlc2.module.BuiltInModuleHelper;
import tlc2.overrides.Evaluation;
import tlc2.overrides.TLAPlusCallable;
import tlc2.overrides.TLAPlusOperator;
import tlc2.tool.EvalException;
import tlc2.tool.impl.FastTool;
import tlc2.tool.impl.TLARegistry;
import tlc2.value.impl.Value;
import tla2sany.semantic.ModuleNode;
import tla2sany.semantic.OpDefNode;
import util.SimpleFilenameToStream;
import util.ToolIO;

import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

/**
 * StandardModule override oracle for unit 6C (plan-2 Phase C, step C1).
 *
 * Two modes:
 *
 *   ModuleOpDump --inventory
 *     Reflects over the tlc2.module classes and prints one row per public
 *     static method: the TLA+ identifier it binds to (after TLARegistry
 *     name mapping), its arity, parameter/return types, override annotation,
 *     and whether the class counts as a built-in module. This is the family-4
 *     registry contract, read off the pinned tree rather than transcribed.
 *
 *   ModuleOpDump <base>   (cwd holds <base>.tla and <base>.cfg)
 *     Builds a FastTool and prints
 *       BINDINGS  one row per definition visible in the root module that
 *                 originates in another module, saying what the definition
 *                 resolved to (a Java override value, or its TLA+ body).
 *       EVAL      the EvalDump projection of every arity-0 root definition,
 *                 with the TLC error code on a typed failure.
 *
 * Fields are `|`-separated; Java object identities, timing, and coverage are
 * excluded. Method.toString() names the bound Java method (stable at the pin).
 */
public final class ModuleOpDump {

  /** Every operator-bearing class in tlc2.module (helpers excluded). The
   *  generator cross-checks this list against the pinned source directory,
   *  so a class added upstream cannot slip past the inventory. */
  private static final String[] MODULES = {
    "tlc2.module.AnySet",
    "tlc2.module.Bags",
    "tlc2.module.FiniteSets",
    "tlc2.module.Integers",
    "tlc2.module.Json",
    "tlc2.module.Naturals",
    "tlc2.module.Randomization",
    "tlc2.module.Sequences",
    "tlc2.module.Strings",
    "tlc2.module.TLC",
    "tlc2.module.TLCEval",
    "tlc2.module.TLCExt",
    "tlc2.module.TLCGetSet",
    "tlc2.module.TransitiveClosure",
    "tlc2.module._JsonTrace",
    "tlc2.module._Possible",
    "tlc2.module._TLCTrace",
  };

  public static void main(String[] args) {
    if (args.length > 0 && args[0].equals("--inventory")) {
      inventory();
    } else if (args.length > 1 && args[0].equals("--declared")) {
      declared(args[1]);
    } else {
      spec(args[0]);
    }
  }

  // +| declared mode: which identifiers a StandardModule actually defines
  //    (an override binds by name, so a Java method with no TLA+ declaration
  //    is unreachable — that fact is read off the pin, not assumed)

  private static void declared(String base) {
    StringBuilder out = new StringBuilder("DECLARED\n");
    java.io.ByteArrayOutputStream errBuf = new java.io.ByteArrayOutputStream();
    try {
      java.io.PrintStream errPs = new java.io.PrintStream(errBuf, true, "UTF-8");
      tla2sany.modanalyzer.SpecObj spec =
        new tla2sany.modanalyzer.SpecObj(base, new SimpleFilenameToStream());
      tla2sany.drivers.SANY.parse(spec, base,
        new tla2sany.output.SimpleSanyOutput(errPs, tla2sany.output.LogLevel.ERROR),
        new tla2sany.drivers.SanySettings(true, true, true, false));
      tla2sany.semantic.ExternalModuleTable emt = spec.getExternalModuleTable();
      List<String> rows = new ArrayList<>();
      for (ModuleNode m : emt.getModuleNodes()) {
        String mod = m.getName().toString();
        if (mod.equals(base)) continue;
        for (OpDefNode d : m.getOpDefs()) {
          if (d.getOriginallyDefinedInModuleNode() != m) continue;
          rows.add(String.join("|", mod, d.getName().toString(),
                   String.valueOf(d.getArity()), d.isLocal() ? "local" : "public"));
        }
      }
      rows.sort(Comparator.naturalOrder());
      for (String r : rows) out.append(r).append("\n");
    } catch (Throwable t) {
      out.append("LOAD|").append(t.getClass().getSimpleName())
         .append(": ").append(msg(t)).append("\n");
    }
    System.out.print(out);
  }

  // +| inventory mode

  private static void inventory() {
    StringBuilder out = new StringBuilder("INVENTORY\n");
    List<Class<?>> classes = new ArrayList<>();
    for (String name : MODULES) {
      try {
        // initialize=true so the static TLARegistry.put blocks have run
        // before any method name is mapped
        classes.add(Class.forName(name, true, ModuleOpDump.class.getClassLoader()));
      } catch (Throwable t) {
        out.append("LOAD|").append(name).append("|").append(t.getClass().getSimpleName())
           .append(": ").append(msg(t)).append("\n");
      }
    }
    List<String> rows = new ArrayList<>();
    for (Class<?> c : classes) {
      boolean builtin = BuiltInModuleHelper.isBuiltInModule(c);
      for (Method m : c.getDeclaredMethods()) {
        int mod = m.getModifiers();
        if (!Modifier.isPublic(mod) || !Modifier.isStatic(mod)) continue;
        String tla = TLARegistry.mapName(m.getName());
        rows.add(String.join("|",
          c.getSimpleName(),
          builtin ? "builtin" : "user",
          tla,
          String.valueOf(m.getParameterCount()),
          m.getName(),
          params(m),
          m.getReturnType().getSimpleName(),
          annotation(m)));
      }
    }
    rows.sort(Comparator.naturalOrder());
    for (String r : rows) out.append(r).append("\n");
    System.out.print(out);
  }

  private static String params(Method m) {
    Class<?>[] ps = m.getParameterTypes();
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < ps.length; i++) {
      if (i > 0) sb.append(",");
      sb.append(ps[i].getSimpleName());
    }
    return sb.length() == 0 ? "-" : sb.toString();
  }

  /** The override annotation, or `-` for a plain name-mapped MethodValue. */
  private static String annotation(Method m) {
    Annotation a = m.getAnnotation(TLAPlusOperator.class);
    if (a != null) {
      TLAPlusOperator o = (TLAPlusOperator) a;
      return "TLAPlusOperator(" + o.module() + "!" + o.identifier()
           + ",minLevel=" + o.minLevel() + ",warn=" + o.warn() + ")";
    }
    a = m.getAnnotation(Evaluation.class);
    if (a != null) {
      Evaluation e = (Evaluation) a;
      return "Evaluation(" + e.module() + "!" + e.definition()
           + ",minLevel=" + e.minLevel() + ",warn=" + e.warn() + ")";
    }
    a = m.getAnnotation(TLAPlusCallable.class);
    if (a != null) {
      TLAPlusCallable c = (TLAPlusCallable) a;
      return "TLAPlusCallable(" + c.module() + "!" + c.definition()
           + ",minLevel=" + c.minLevel() + ")";
    }
    return "-";
  }

  // +| spec mode

  private static void spec(String base) {
    ToolIO.setMode(ToolIO.TOOL);
    ToolIO.setUserDir(System.getProperty("user.dir"));
    StringBuilder out = new StringBuilder();
    FastTool tool;
    try {
      tool = new FastTool(base, base, new SimpleFilenameToStream());
    } catch (Throwable t) {
      out.append("LOAD ! ").append(t.getClass().getSimpleName())
         .append(": ").append(msg(t)).append("\n");
      System.out.print(out);
      return;
    }
    ModuleNode root = tool.getModule(base);
    OpDefNode[] defs = root.getOpDefs();
    OpDefNode[] sorted = Arrays.copyOf(defs, defs.length);
    Arrays.sort(sorted, Comparator.comparing(d -> key(d)));

    out.append("BINDINGS\n");
    for (OpDefNode d : sorted) {
      ModuleNode org = d.getOriginallyDefinedInModuleNode();
      if (org == null) continue;
      String mod = org.getName().toString();
      if (mod.equals(base)) continue;              // root definitions: EVAL below
      out.append(mod).append("!").append(d.getName()).append("/")
         .append(d.getArity()).append("|").append(binding(tool, d)).append("\n");
    }

    out.append("EVAL\n");
    for (OpDefNode d : sorted) {
      if (d.getArity() != 0) continue;
      ModuleNode org = d.getOriginallyDefinedInModuleNode();
      if (org == null || !org.getName().toString().equals(base)) continue;
      String name = d.getName().toString();
      try {
        Value v = (Value) tool.eval(d.getBody());
        out.append(name).append(" ").append(v.getClass().getSimpleName())
           .append(" ").append(v.toString()).append("\n");
      } catch (Throwable t) {
        out.append(name).append(" ! ").append(ec(t))
           .append(t.getClass().getSimpleName()).append(": ").append(msg(t)).append("\n");
      }
    }
    System.out.print(out);
  }

  /** What a definition resolved to: the Java override that bound to it, or
   *  its TLA+ body. `Evaluation`-annotated overrides sit on the body, so the
   *  body's tool object is consulted too. */
  private static String binding(FastTool tool, OpDefNode d) {
    Object o = tool.lookup(d);
    if (o != null && o != d) return "override:" + o.getClass().getSimpleName();
    Integer id = toolId();
    if (id != null && d.getBody() != null) {
      Object b = d.getBody().getToolObject(id);
      if (b != null) return "body-override:" + b.getClass().getSimpleName();
    }
    return "body";
  }

  /** tlc2.tool.impl.Spec.toolId is protected static; the oracle reads it
   *  reflectively to see body-level (Evaluation/Callable) overrides. */
  private static Integer toolId() {
    try {
      Field f = Class.forName("tlc2.tool.impl.Spec").getDeclaredField("toolId");
      f.setAccessible(true);
      return f.getInt(null);
    } catch (Throwable t) {
      return null;
    }
  }

  private static String key(OpDefNode d) {
    ModuleNode org = d.getOriginallyDefinedInModuleNode();
    return (org == null ? "" : org.getName().toString()) + "!" + d.getName();
  }

  /** `EC<code> ` for a typed TLC failure, empty otherwise. */
  private static String ec(Throwable t) {
    if (t instanceof EvalException) {
      return "EC" + ((EvalException) t).getErrorCode() + " ";
    }
    return "";
  }

  private static String msg(Throwable t) {
    String m = t.getMessage();
    if (m == null) return "";
    return m.replace("\n", " ").trim();
  }
}
