import java.util.zip.CRC32;
public class CrcVec {
  static String cs(String s){ CRC32 c=new CRC32(); c.update(s.getBytes()); return Long.toHexString(c.getValue()); }
  public static void main(String[] a){
    String[] t = {"", "a", "abc", "The quick brown fox jumps over the lazy dog",
                  "--algorithm Counter", "hello\nworld", "chksum(pcal)"};
    for(String s: t) System.out.println("\""+s.replace("\n","\\n")+"\" -> "+cs(s));
  }
}
