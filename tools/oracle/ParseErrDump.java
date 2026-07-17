import tla2sany.output.LogLevel;
import tla2sany.output.SanyOutput;
import tla2sany.parser.TLAplusParser;

import java.io.FileInputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Dumps the exact parse-error text SANY's TLAplusParser produces, for
 * differential diagnostic testing (PORT-COMPLETION-PLAN-2 unit 2).
 *
 * ACCEPT alone when the parse succeeds; otherwise REJECT followed by the
 * verbatim reportedError() text of every ParseError the parser pushed, in
 * order, each terminated by a line containing only "%%".  The parser logs
 * each error via SanyOutput at ERROR level, so a capturing output sees
 * exactly the PErrors list without needing package access.
 */
public final class ParseErrDump {

  private static final class Capture implements SanyOutput {
    final List<String> errors = new ArrayList<>();
    @Override public void log(LogLevel level, String format, Object... args) {
      if (level == LogLevel.ERROR) {
        errors.add(args.length == 0 ? format : String.format(format, args));
      }
    }
    @Override public PrintStream getStream(LogLevel level) {
      return new PrintStream(java.io.OutputStream.nullOutputStream());
    }
  }

  public static void main(String[] args) throws Exception {
    byte[] bytes = new FileInputStream(args[0]).readAllBytes();
    Capture cap = new Capture();
    TLAplusParser parser = new TLAplusParser(cap, bytes);
    boolean ok;
    String crash = null;
    try {
      ok = parser.parse();
    } catch (Throwable t) {
      ok = false;
      crash = t.getClass().getSimpleName();
    }
    if (ok) {
      System.out.println("ACCEPT");
      return;
    }
    StringBuilder out = new StringBuilder("REJECT\n");
    for (String e : cap.errors) {
      out.append(e).append("\n%%\n");
    }
    if (crash != null) {
      out.append("CRASH ").append(crash).append("\n%%\n");
    }
    System.out.print(out);
  }
}
