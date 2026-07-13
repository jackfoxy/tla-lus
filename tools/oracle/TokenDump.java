import tla2sany.parser.SimpleCharStream;
import tla2sany.parser.TLAplusParserConstants;
import tla2sany.parser.TLAplusParserTokenManager;
import tla2sany.parser.Token;
import tla2sany.parser.TokenMgrError;

import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * Dumps the raw SANY token stream for differential lexer testing.
 *
 * One line per token/special/error:
 *   C <bl>.<bc> <el>.<ec> <image>     comment (special token)
 *   T <kind> <bl>.<bc> <el>.<ec> <image>
 *   E <message>                        lexical error (terminates dump)
 *
 * Images and messages are escaped: backslash, LF, CR, TAB.
 * Dumping stops when module nesting returns to zero (SANY never lexes
 * past the root module's ====), or at EOF for module-less input.
 */
public final class TokenDump {

  public static void main(String[] args) throws Exception {
    byte[] bytes = new FileInputStream(args[0]).readAllBytes();
    String text = new String(bytes, StandardCharsets.UTF_8);
    Map<Integer, String> names = kindNames();
    StringBuilder out = new StringBuilder();

    SimpleCharStream stream = new SimpleCharStream(new StringReader(text), 1, 1);
    TLAplusParserTokenManager mgr = new TLAplusParserTokenManager(stream);
    int bm0 = kindOf("_BM0"), bm1 = kindOf("_BM1"), bm2 = kindOf("_BM2");
    int endModule = kindOf("END_MODULE");
    int depth = 0;
    boolean sawModule = false;

    try {
      while (true) {
        Token tok = mgr.getNextToken();
        for (Token sp = firstSpecial(tok); sp != null; sp = sp.next) {
          out.append("C ").append(span(sp)).append(' ')
             .append(esc(sp.image)).append('\n');
        }
        if (tok.kind == 0) {
          break;                                    // EOF
        }
        String name = names.getOrDefault(tok.kind, "k" + tok.kind);
        out.append("T ").append(name).append(' ').append(span(tok))
           .append(' ').append(esc(tok.image)).append('\n');
        if (tok.kind == bm0 || tok.kind == bm1 || tok.kind == bm2) {
          depth++;
          sawModule = true;
        } else if (tok.kind == endModule) {
          depth--;
          if (sawModule && depth == 0) {
            break;
          }
        }
      }
    } catch (TokenMgrError e) {
      out.append("E ").append(esc(e.getMessage())).append('\n');
    }
    System.out.print(out);
  }

  private static Token firstSpecial(Token tok) {
    if (tok.specialToken == null) {
      return null;
    }
    Token sp = tok.specialToken;
    while (sp.specialToken != null) {
      sp = sp.specialToken;
    }
    return sp;
  }

  private static String span(Token t) {
    return t.beginLine + "." + t.beginColumn + " " + t.endLine + "." + t.endColumn;
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
        default: b.append(c);
      }
    }
    return b.toString();
  }

  private static int kindOf(String name) throws Exception {
    return TLAplusParserConstants.class.getField(name).getInt(null);
  }

  // lexical-state constants share the int space with token kinds
  private static final java.util.Set<String> STATES = java.util.Set.of(
      "DEFAULT", "PRAGMA", "SPEC", "IN_COMMENT", "EMBEDDED", "IN_EOL_COMMENT");

  private static Map<Integer, String> kindNames() {
    Map<Integer, String> map = new HashMap<>();
    for (Field f : TLAplusParserConstants.class.getFields()) {
      if (!Modifier.isStatic(f.getModifiers()) || f.getType() != int.class
          || STATES.contains(f.getName())) {
        continue;
      }
      try {
        int v = f.getInt(null);
        String kebab = f.getName().toLowerCase().replace('_', '-');
        while (kebab.startsWith("-")) {
          kebab = kebab.substring(1);
        }
        // first declaration wins (constants file lists token kinds once)
        map.putIfAbsent(v, kebab);
      } catch (IllegalAccessException ignored) { }
    }
    return map;
  }
}
