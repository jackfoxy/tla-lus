package tla2sany.semantic;

/**
 * Build-time oracle helper (unit 4 level checking): renders the
 * package-private constraint-set element types with stable names only.
 * Their own toString() embeds SymbolNode UIDs, which are volatile across
 * runs, so SemDump must not use them directly.
 */
public final class LevelProbe {

  private LevelProbe() {}

  /** ParamAndPosition -> "(name,pos)" */
  public static String pap(Object o) {
    ParamAndPosition p = (ParamAndPosition) o;
    return "(" + p.param.getName() + "," + p.position + ")";
  }

  /** ArgLevelParam -> "(opname,pos,paramname)" */
  public static String alp(Object o) {
    ArgLevelParam a = (ArgLevelParam) o;
    return "(" + a.op.getName() + "," + a.i + "," + a.param.getName() + ")";
  }
}
